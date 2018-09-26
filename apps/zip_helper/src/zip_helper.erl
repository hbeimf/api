-module(zip_helper).
-compile(export_all).

zip() -> 
	CurriculumList = mysqlc:select_curriculum_list_all(),
	foreach_zip(CurriculumList).

foreach_zip({ok, []}) ->
	ok;
foreach_zip({ok, List}) -> 
	lists:foldl(fun(L, Reply) -> 
		{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, L),
		% {_, {_, Oid}, _} = lists:keytake(<<"oid">>, 1, L),
		% R = zip(Id, Oid),
		R = zip(Id, Id),
		[R|Reply]
	end, [], List).

zip(CurriculumId, Oid) ->
	UrlList = urls(CurriculumId),
	Dir = create_zips_dir(Oid),
	FileDirList = download_file(UrlList, Dir),
	% ZipDir = zips_dir() ++ "/"++ glib:to_str(Oid) ++".zip",
	ZipDir = get_zip_dest_dir(Oid),
	L = parse_dir(lists:usort(FileDirList)),

	io:format("mod:~p, line:~p==================~n param:~p ~n~n", [?MODULE, ?LINE, {ZipDir, L, zips_dir()}]),
	case length(L) > 0  of 
		true -> 
			zip:zip(ZipDir, L, [{cwd, zips_dir()}]);
		_ -> 
			ok
	end.

get_zip_dest_dir(Oid) -> 
	case sys_config:get_config(htgl) of
		{ok, Config} -> 
			{_, {zip, Zip}, _} = lists:keytake(zip, 1, Config),
			Dir = case glib:is_dir(Zip) of
				true -> 
					Zip;
				_ -> 
					glib:make_dir(Zip),
					Zip
			end,
			Dir ++ "/course_"++ glib:to_str(Oid) ++".zip";
		_ -> 
			ok
	end.

parse_dir([]) -> 
	[];
parse_dir(FileDirList) ->
	ZipsDir = zips_dir() ++ "/",
	lists:foldl(fun(FileDir, Reply) -> 
		F = glib:replace(FileDir, ZipsDir, ""),
		[F|Reply]
	end, [], FileDirList).

download_file([], _Dir) -> 
	[];
download_file(UrlList, Dir) ->
	lists:foldl(fun(Url, Reply) -> 
		Name = parse_name_from_url(Url),
		FileDir = Dir ++ "/" ++ Name,
		case glib:file_exists(FileDir) of 
			true -> 
				[FileDir|Reply];
			_ ->
				case glib:http_get(Url) of
					<<"">> ->
						Reply;
					Body ->
						glib:file_put_contents(FileDir, Body),
						[FileDir|Reply]
				end
		end
	end, [], UrlList). 

parse_name_from_url(Url) ->
	L = glib:explode(glib:to_str(Url), "/"),
	lists:last(L).

create_zips_dir(Oid) ->
	Dir = zips_dir(),
	case glib:is_dir(Dir) of
		true ->   
			ok;
		_ -> 
			glib:make_dir(Dir)
	end,
	ZipDir = Dir ++ "/course_" ++ glib:to_str(Oid),
	case glib:is_dir(ZipDir) of
		true-> 
			ok;
		_ ->
			glib:make_dir(ZipDir)
	end,
	ZipDir.

zips_dir() -> 
	glib:root_dir() ++ "zips".

urls(CurriculumId) -> 
	StepList = mysqlc:select_curriculum(CurriculumId),
	Urls = lists:foldl(fun(Step, Res) -> 
		{_, {_, InfoList}, _} = lists:keytake(<<"info">>, 1, Step),
		UrlList = foreach_info(InfoList, <<"url">>),
		XmlUrlList = foreach_info(InfoList, <<"xml_url">>),
		BgUrlList = foreach_info(InfoList, <<"bg_url">>),
		[UrlList, XmlUrlList, BgUrlList|Res]
	end, [], StepList),
	lists:flatten(Urls).

foreach_info([], _Key) ->
	[];
foreach_info(InfoList, Key) ->
	lists:foldl(fun(Info, Reply) -> 
		case lists:keytake(Key, 1, Info) of 
			{_, {_, <<"">>}, _}  ->
				Reply; 
			{_, {_, Url}, _}  -> 
				[Url|Reply];
			_ -> 
				Reply
		end
	end, [], InfoList).



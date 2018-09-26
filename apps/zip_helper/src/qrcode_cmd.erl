-module(qrcode_cmd).
-compile(export_all).

-include("state.hrl").

make() -> 
	schools(),
	ok.


make_teacher(SchoolId) -> 
	Role = "teacher",
	Dir = create_zips_dir(SchoolId, Role),
	% ?LOG({SchoolId, Dir}),
	UrlList = teacher(SchoolId),
	FileDirList = download_file(UrlList, Dir),
	?LOG({UrlList, FileDirList}),

	ZipDir = get_zip_dest_dir(SchoolId, Role),
	L = parse_dir(lists:usort(FileDirList)),

	io:format("mod:~p, line:~p==================~n param:~p ~n~n", [?MODULE, ?LINE, {ZipDir, L, zips_dir()}]),
	case length(L) > 0  of 
		true -> 
			zip:zip(ZipDir, L, [{cwd, zips_dir()}]);
		_ -> 
			ok
	end,
	ok.

make_student(SchoolId) ->
	Role = "student",
	Dir = create_zips_dir(SchoolId, Role),
	% ?LOG({SchoolId, Dir}),
	UrlList = student(SchoolId),
	FileDirList = download_file(UrlList, Dir),
	?LOG({UrlList, FileDirList}),

	ZipDir = get_zip_dest_dir(SchoolId, Role),
	L = parse_dir(lists:usort(FileDirList)),

	io:format("mod:~p, line:~p==================~n param:~p ~n~n", [?MODULE, ?LINE, {ZipDir, L, zips_dir()}]),
	case length(L) > 0  of 
		true -> 
			zip:zip(ZipDir, L, [{cwd, zips_dir()}]);
		_ -> 
			ok
	end,
	ok.

get_zip_dest_dir(SchoolId, Role) -> 
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
			lists:concat([Dir ++ "/", Role, "_"++ glib:to_str(SchoolId) ++".zip"]);
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


create_zips_dir(SchoolId, Role) ->
	Dir = zips_dir(),
	case glib:is_dir(Dir) of
		true ->   
			ok;
		_ -> 
			glib:make_dir(Dir)
	end,
	ZipDir = lists:concat([Dir, "/", Role, "_", glib:to_str(SchoolId)]),
	case glib:is_dir(ZipDir) of
		true-> 
			ok;
		_ ->
			glib:make_dir(ZipDir)
	end,
	ZipDir.

zips_dir() -> 
	glib:root_dir() ++ "zips".

student(SchoolId) ->
	Sql = "SELECT id, name FROM t_student",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, []),
	{ok, Students} = mysqlc:parse_res(Res),
	Domain = domain(),
	Urls = lists:foldl(fun(Student, Res) -> 
		{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, Student),
		% ?LOG({SchoolId, Id}),
		Url = lists:concat([Domain, "/qrcode/student_", Id, ".png"]),
		[Url|Res]
	end, [], Students).


teacher(SchoolId) ->
	Sql = "SELECT id, name FROM t_teacher",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, []),
	{ok, Students} = mysqlc:parse_res(Res),
	Domain = domain(),
	Urls = lists:foldl(fun(Student, Res) -> 
		{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, Student),
		% ?LOG({SchoolId, Id}),
		Url = lists:concat([Domain, "/qrcode/teacher_", Id, ".png"]),
		[Url|Res]
	end, [], Students).


domain() -> 
    case  sys_config:get_config(htgl) of
        {ok, Config} -> 
            {_, {_, Domain}, _} = lists:keytake(domain, 1, Config),
            Domain;
        _ -> 
            ""
    end.

schools() -> 
	Sql = "SELECT id, name FROM t_school_organization",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, []),
	{ok, Schools} = mysqlc:parse_res(Res),
	lists:foreach(fun(School) -> 
		{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, School),
		{_, {_, Name}, _} = lists:keytake(<<"name">>, 1, School),
		make_teacher(Id),
		make_student(Id),
		ok
	end, Schools),
	ok.

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


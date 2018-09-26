% /**
% 	 * 4> 课程详情
% 	 * http://m1.demo.com/api/curriculumInfo/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&curriculum_id=1
% http://m2.demo.com/api/curriculumInfo/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&curriculum_id=1
% 	 * school_id: 机构id
% 	 * mac: 设备mac
% 	 * token:
% 	 * curriculum_id: 课程 id
% 	 */

-module(handler_curriculum_info).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{Method, Req2} = cowboy_req:method(Req),
	{SchoolId, _} = cowboy_req:qs_val(<<"school_id">>, Req2),
	{Mac, _} = cowboy_req:qs_val(<<"mac">>, Req2),
	{Token, _} = cowboy_req:qs_val(<<"token">>, Req2),
	{CurriculumId, _} = cowboy_req:qs_val(<<"curriculum_id">>, Req2),

	{ok, Req4} = reply(Method, SchoolId, Mac, Token, CurriculumId, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolId, _Mac, _Token, _CurriculumId, Req) when SchoolId =:= undefined orelse SchoolId =:= <<"">> ->
	Msg = unicode:characters_to_binary("机构编号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, Mac, _Token, _CurriculumId, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, Token, _CurriculumId, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, _Token, CurriculumId, Req) when CurriculumId =:= undefined orelse CurriculumId =:= <<"">> ->
	Msg = unicode:characters_to_binary("课程ID出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolId, Mac, Token, CurriculumId, Req) ->
             case logic:check_token(Token) of 
             	true -> 
             		case logic:has_activate(SchoolId, Mac) of 
             			true -> 
					% CurriculumInfo = select_curriculum(select_id(CurriculumId)),
					{CurriculumInfo, Version} = select_curriculum(CurriculumId),
					ZipUrl = get_zip_dir(CurriculumId),
		             		Data = [{<<"flg">>, true}, {<<"msg">>, <<"">>},{<<"version">>, Version}, {<<"data">>, CurriculumInfo}, {<<"zip_url">>, ZipUrl}],
					Json = jsx:encode(Data),
					cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
				_ -> 
					Msg = unicode:characters_to_binary("设备未激活!! "),	
		             		Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
					Json = jsx:encode(Data),
					cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
			end;

             	_ -> 
             		Msg = unicode:characters_to_binary("token 出错!! "),	
             		Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
			Json = jsx:encode(Data),
			cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
             end;

reply(_,  _SchoolId, _Mac, _Token, _CurriculumId, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


% priv fun ==============================
get_zip_dir(Oid) -> 
	case sys_config:get_config(htgl) of
		{ok, Config} -> 
			{_, {zip, Zip}, _} = lists:keytake(zip, 1, Config),
			{_, {domain, Domain}, _} = lists:keytake(domain, 1, Config),

			ZipDir = Zip ++ "/course_"++ glib:to_str(Oid) ++".zip",
			case glib:file_exists(ZipDir) of
				true -> 
					Url = Domain ++ "/zips/course_" ++ glib:to_str(Oid) ++".zip",
					glib:to_binary(Url);
				_ -> 
					<<"">>
			end;
		_ -> 
			<<"">>
	end.

select_id(OrderBy) -> 
	Sql = "SELECT id FROM t_curriculum WHERE order_by = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [OrderBy]),
	case parse_res(Res) of 
		{ok, []} -> 
			0;
		{ok, [Row]} -> 
			{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, Row),	
			Id
	end.

select_curriculum(CurriculumId) -> 
	% Sql = "SELECT id, name, res_type, ppt_id, music_id, version_num FROM t_curriculum_step WHERE curriculum_id = ? ORDER BY id ASC",
	Sql = "SELECT id, name, res_type, ppt_id, music_id, version_num FROM t_curriculum_step WHERE curriculum_id = ? AND is_enabled=1 ORDER BY id ASC",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [CurriculumId]),
	{ok, StepList} = parse_res(Res),

	{Info, _V} = lists:foldl(fun(Step, {Reply, Version}) -> 
		{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, Step),
		{_, {_, Name}, _} = lists:keytake(<<"name">>, 1, Step),
		{_, {_, ResType}, _} = lists:keytake(<<"res_type">>, 1, Step),
		{_, {_, PptId}, _} = lists:keytake(<<"ppt_id">>, 1, Step),
		{_, {_, MusicId}, _} = lists:keytake(<<"music_id">>, 1, Step),
		{_, {_, VersionNum}, _} = lists:keytake(<<"version_num">>, 1, Step),


		{TplType, Info} = curriculum_step_info(ResType, PptId, MusicId),
		StepInfo = [
			{<<"id">>, Id}, 
			{<<"name">>, Name}, 
			{<<"type">>, ResType}, 
			{<<"version">>, VersionNum}, 
			{<<"tpl_type">>, TplType}, 
			{<<"info">>, Info}
		],
		{[StepInfo|Reply], Version+VersionNum}
	end, {[], 0}, StepList),

	CVersion = get_curriculum_version(CurriculumId),
	{Info, CVersion}.

get_curriculum_version(CurriculumId) -> 
	Sql = "SELECT version_num FROM t_curriculum WHERE id = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [CurriculumId]),
	case parse_res(Res) of 
		{ok, []} -> 
			1;
		{ok, [R|_]} -> 
			{_, {_, Version}, _} = lists:keytake(<<"version_num">>, 1, R),
			Version
	end.

% tpl_type
%% 日字模板
tpl_type(1, [_Area1, Area2]) ->
	% [_Area1, Area2] = PptInfo,
	{_, {_, Mp3Type}, _} = lists:keytake(<<"mp3_type">>, 1, Area2),
	% io:format("mod:~p, line:~p, data: ~p~n", [?MODULE, ?LINE, Area2]),
	case Mp3Type of 
		0 -> 
			1;
		_ -> 
			2
	end;
%% 田字模板  
tpl_type(2, PptInfo) ->
	 
	 Flg = lists:foldl(fun(Info, Result) -> 
	 	{_, {_, Mp3Type}, _} = lists:keytake(<<"mp3_type">>, 1, Info),
	 	Result + Mp3Type
	 end, 0, PptInfo),
	 % io:format("mod:~p, line:~p, data: ~p~n", [?MODULE, ?LINE, Flg]),

	 %% 当Flg 为 3 时， 说明3个都是背景音乐 ，返回 3, 否则至少有一个手动播放，返回 4
	 case Flg of 
	 	3 -> 
	 		3;
	 	_ -> 
	 		4
	 end.
	% 3. 


% ppt
curriculum_step_info(1, PptId, _MusicId) ->
	Sql = "SELECT class_type, area1, area2, area3, area4 FROM t_ppt WHERE id = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [PptId]),
	{ok, [Ppt|_]} = parse_res(Res),

	{_, {_, ClassType}, _} = lists:keytake(<<"class_type">>, 1, Ppt),
	{_, {_, Area1}, _} = lists:keytake(<<"area1">>, 1, Ppt),
	{_, {_, Area2}, _} = lists:keytake(<<"area2">>, 1, Ppt),
	{_, {_, Area3}, _} = lists:keytake(<<"area3">>, 1, Ppt),
	{_, {_, Area4}, _} = lists:keytake(<<"area4">>, 1, Ppt),

	PptInfo = ppt_info(ClassType, Area1, Area2, Area3, Area4),
	{tpl_type(ClassType, PptInfo), PptInfo};
% music
curriculum_step_info(2, _PptId, MusicId) ->
	Sql = "SELECT name, png, xml, mp3, mp3_demo FROM t_music WHERE id = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [MusicId]),
	{ok, [Music|_]} = parse_res(Res),

	{_, {_, Name}, _} = lists:keytake(<<"name">>, 1, Music),
	{_, {_, Png}, _} = lists:keytake(<<"png">>, 1, Music),
	{_, {_, Xml}, _} = lists:keytake(<<"xml">>, 1, Music),
	{_, {_, Mp3}, _} = lists:keytake(<<"mp3">>, 1, Music),
	{_, {_, Mp3Demo}, _} = lists:keytake(<<"mp3_demo">>, 1, Music),

	% MusicInfo = [
	% 	{<<"name">>, Name},
	% 	{<<"png">>, res_info(Png)},
	% 	{<<"xml">>, res_info(Xml)},
	% 	{<<"mp3">>, res_info(Mp3)},
	% 	{<<"mp3_demo">>, res_info(Mp3Demo)}
	% ],

	{PngUrl, PngMd5} = res_info(Png),
	{XmlUrl, XmlMd5} = res_info(Xml),
	Area1Info = [
		{<<"type">>, 1},
		{<<"name">>, Name},
		{<<"desc">>, <<"">>},
		{<<"mp3_type">>, 0},
		{<<"url">>, PngUrl},
		{<<"md5">>, PngMd5},
		{<<"xml_url">>, XmlUrl},
		{<<"xml_md5">>, XmlMd5},
		{<<"bg_url">>, <<"">>},
		{<<"bg_md5">>, <<"">>}
	],

	{Mp3Url, Mp3Md5} = res_info(Mp3),
	{Mp3DemoUrl, Mp3DemoMd5} = res_info(Mp3Demo),
	Area2Info = [
		{<<"type">>, 2},
		{<<"name">>, Name},
		{<<"desc">>, <<"">>},
		{<<"mp3_type">>, 0},
		{<<"url">>, Mp3Url},
		{<<"md5">>, Mp3Md5},
		{<<"xml_url">>, <<"">>},
		{<<"xml_md5">>, <<"">>},
		{<<"bg_url">>, Mp3DemoUrl},
		{<<"bg_md5">>, Mp3DemoMd5}
	],

	MusicInfo = [
		[{<<"type">>, 1}|Area1Info],
		[{<<"type">>, 2}|Area2Info]
	],

	{0, MusicInfo}.

res_info(Id) when Id > 0 -> 
	Sql = "SELECT name, url, md5 FROM t_resource WHERE id = ? ",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Id]),
	% {ok, [R|_]} = parse_res(Res),
	case parse_res(Res) of 
		{ok, []} -> 
			{<<"">>, <<"">>};
		{ok, [R|_]} -> 
			% {_, {_, Name}, _} = lists:keytake(<<"name">>, 1, R),
			{_, {_, Url}, _} = lists:keytake(<<"url">>, 1, R),
			{_, {_, Md5}, _} = lists:keytake(<<"md5">>, 1, R),

			{Url, Md5}
	end;
	% [{<<"name">>, Name}, {<<"url">>, Url}, {<<"md5">>, Md5}];
res_info(_) ->
	{<<"">>, <<"">>}. 
	% [].

ppt_info(ClassType, Area1, Area2, _Area3, _Area4) when ClassType =:= 1->
	Area1Info = img_info(Area1),
	Area2Info = font_info(Area2),
	[
		% [{<<"tpl_type">>, ClassType}],
		[{<<"type">>, 1}|Area1Info],
		[{<<"type">>, 2}|Area2Info]
	];
	
	% [
	% 	{<<"tpl_type">>, ClassType},
	% 	{<<"area1">>, img_info(Area1)},
	% 	{<<"area2">>, font_info(Area2)}
	% ];
	
ppt_info(_ClassType, Area1, Area2, Area3, Area4) ->
	Area1Info = font_info(Area1),
	Area2Info = img_info(Area2),
	Area3Info = font_info(Area3),
	Area4Info = font_info(Area4),

	[
		% [{<<"tpl_type">>, ClassType}],
		[{<<"type">>, 1}|Area1Info],
		[{<<"type">>, 2}|Area2Info],
		[{<<"type">>, 3}|Area3Info],
		[{<<"type">>, 4}|Area4Info]
	].


	% [
	% 	{<<"tpl_type">>, ClassType},
	% 	{<<"1">>, [{<<"type">>, 1}|Area1Info]},
	% 	{<<"2">>, [{<<"type">>, 2}|Area2Info]},
	% 	{<<"3">>, [{<<"type">>, 3}|Area3Info]},
	% 	{<<"4">>, [{<<"type">>, 4}|Area4Info]}
	% ].

	% [
	% 	{<<"tpl_type">>, ClassType},
	% 	{<<"area1">>, font_info(Area1)},
	% 	{<<"area2">>, img_info(Area2)},
	% 	{<<"area3">>, font_info(Area3)},
	% 	{<<"area4">>, font_info(Area4)}
	% ].

img_info(Id) when Id > 0 ->
	Sql = "SELECT a.name, b.url, b.md5 FROM t_picture as a LEFT JOIN t_resource as b ON a.pic = b.id WHERE a.id = ? ",
	Res1 = mysql_poolboy:query(mysqlc:pool(), Sql, [Id]),
	{ok, [Ppt1|_]} = parse_res(Res1),

	{_, {_, Name}, _} = lists:keytake(<<"name">>, 1, Ppt1),
	{_, {_, Url}, _} = lists:keytake(<<"url">>, 1, Ppt1),
	{_, {_, Md5}, _} = lists:keytake(<<"md5">>, 1, Ppt1),

	 [
		 {<<"name">>, Name}, 
		 {<<"desc">>, <<"">>}, 
		 {<<"mp3_type">>, 0}, 
		 {<<"url">>, Url}, 
		 {<<"md5">>, Md5}
	 ];
	 % [{<<"name">>, Name}, {<<"url">>, Url}, {<<"md5">>, Md5}];

img_info(_) -> 
	[].

font_info(Id) when Id > 0  -> 
	Sql = "SELECT a.font, a.mp3_desc, a.mp3_type, b.url, b.md5 FROM t_font as a LEFT JOIN t_resource as b ON a.mp3 = b.id WHERE a.id = ? ",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Id]),
	{ok, [Ppt|_]} = parse_res(Res),

	{_, {_, Font}, _} = lists:keytake(<<"font">>, 1, Ppt),
	{_, {_, Mp3Desc}, _} = lists:keytake(<<"mp3_desc">>, 1, Ppt),
	{_, {_, Mp3Type}, _} = lists:keytake(<<"mp3_type">>, 1, Ppt),
	{_, {_, Url}, _} = lists:keytake(<<"url">>, 1, Ppt),
	{_, {_, Md5}, _} = lists:keytake(<<"md5">>, 1, Ppt),

	 [
	 	{<<"name">>, Font}, 
	 	{<<"desc">>, Mp3Desc}, 
	 	{<<"mp3_type">>, Mp3Type}, 
	 	{<<"url">>, Url}, 
	 	{<<"md5">>, Md5}
	 ];
	 % [{<<"font">>, Font}, {<<"mp3_desc">>, Mp3Desc}, {<<"mp3_type">>, Mp3Type}, {<<"url">>, Url}, {<<"md5">>, Md5}];

font_info(_) ->
	[]. 

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(_Error) ->  
	{ok, []}.		

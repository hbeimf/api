% /**
% 	 * 5> 学生列表 *
% 	 * http://m1.demo.com/api/studentList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&course_type=1&gender=male&classid=5
% http://m2.demo.com/api/studentList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&course_type=1&gender=male&classid=5
% 	 * school_id: 机构id
% 	 * mac: 设备mac
% 	 * token: 57f20f883e
% 	 * course_type: 课程类型: [{1: 基础课}, {2: 特色课}, {3: 兴趣班}, {4: 考级班}]
% 	 * gender: 性别 : [{male: 男}, {female: 女}]
% 	 * classid: 班级id
% 	 */

-module(handler_student_list).

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
	{CourseType, _} = cowboy_req:qs_val(<<"course_type">>, Req2),
	{Gender, _} = cowboy_req:qs_val(<<"gender">>, Req2),
	{Classid, _} = cowboy_req:qs_val(<<"classid">>, Req2),
	{Online, _} = cowboy_req:qs_val(<<"online">>, Req2),
	{ok, Req4} = reply(Method, SchoolId, Mac, Token, CourseType, Gender, Classid, Online, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolId, _Mac, _Token, _CourseType, _Gender, _Classid, _Online, Req) when SchoolId =:= undefined orelse SchoolId =:= <<"">> ->
	Msg = unicode:characters_to_binary("机构编号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, Mac, _Token, _CourseType, _Gender, _Classid, _Online, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, Token, _CourseType, _Gender, _Classid,  _Online, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolId, Mac, Token, CourseType, Gender, Classid, Online, Req) ->
             case logic:check_token(Token) of 
             	true -> 
             		case logic:has_activate(SchoolId, Mac) of 
             			true -> 
             				{ok, StudentList} = student_list(SchoolId, CourseType, Gender, Classid, Online),
		             		Data = [{<<"flg">>, true}, {<<"msg">>, <<"">>}, {<<"data">>, StudentList}],
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
reply(_,  _SchoolId, _Mac, _Token, _CourseType, _Gender, _Classid, _Online, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.

% priv fun ==============================
student_list(SchoolId, CourseType, Gender, Classid, Online) ->
	Sql = "SELECT a.account_id as uid, a.id, a.name, a.url, a.phone, a.email, a.class_id, c.name as class_name, c.id as class_id, a.school_id,b.name as school_name, a.course_type, a.gender 
		FROM t_student as a 
		LEFT JOIN t_school_organization as b ON a.school_id = b.id 
		LEFT JOIN t_class as c ON a.class_id = c.id 
		WHERE a.school_id = ?",
	{Sql1, Params1} = where_course_type(Sql, CourseType, [glib:to_integer(SchoolId)]),
	{Sql2, Params2} = where_gender(Sql1, Gender, Params1),
	{Sql3, Params3} = where_class_id(Sql2, Classid, Params2),
	Sql4 = Sql3 ++ " ORDER BY a.id ASC", 
	Res = mysql_poolboy:query(mysqlc:pool(), Sql4, lists:reverse(Params3)),
	parse_res(Res, Online, glib:to_integer(SchoolId)).

where_class_id(Sql, Classid, Params) when Classid =:= undefined orelse Classid =:= <<"">> ->
	{Sql, Params};
where_class_id(Sql, Classid, Params) -> 
	{Sql ++ " AND c.id = ? ", [glib:to_integer(Classid)|Params]}.

where_gender(Sql, Gender, Params) when Gender =:= undefined orelse Gender =:= <<"">> ->
	{Sql, Params};
where_gender(Sql, Gender, Params) -> 
	{Sql ++ " AND a.gender = ? ", [Gender|Params]}.

where_course_type(Sql, CourseType, Params) when CourseType =:= undefined orelse CourseType =:= <<"">> ->
	{Sql, Params};
where_course_type(Sql, CourseType, Params) ->
	{Sql ++ " AND FIND_IN_SET(?, a.course_type)", [course_type(glib:to_integer(CourseType))|Params]}.

% 1 => 'base',
% 2 => 'characteristic',
% 3 => 'interest',
% 4 => 'level_examination', 
course_type(1) ->
	<<"base">>;
course_type(2) ->
	<<"characteristic">>;
course_type(3) ->
	<<"interest">>;
course_type(_) ->
	<<"level_examination">>.

parse_res({ok, KeyList, DataList}, Online, SchoolId) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	StudentList = get_online_student(RowList, Online, SchoolId),
	{ok, StudentList};
parse_res(_Error, _Online, _SchoolId) ->
	  % io:format("error: ~p~n", [Error]),
	{ok, []}.		


% get_online_student(StudentList, Online, _SchoolId) when Online =:= undefined orelse Online =:= <<"">> ->
% 	StudentList;
get_online_student(StudentList, <<"1">>, SchoolId) ->
	OnlineId = get_online_student(SchoolId),
	lists:foldl(fun(Student, ReplyList) -> 
		% Id = 23,
		{_, {_, Uid}, _} = lists:keytake(<<"uid">>, 1, Student),
		% io:format("mod:~p, line:~p, data:~p~n", [?MODULE, ?LINE, {Uid, OnlineId}]),
		case lists:member(glib:to_binary(Uid), OnlineId) of
			true -> 
				[Student|ReplyList];
			_ -> 
				ReplyList
		end
	end, [], StudentList);
get_online_student(StudentList, _Online, _SchoolId) ->
	StudentList.

%% 获取学校在线学生
get_online_student(SchoolId) ->
	case redisc:get(school_key(SchoolId)) of
		{ok, undefined} -> 
			[];
		{ok, Binary} -> 
			binary_to_term(Binary)
	end. 
	
school_key(SchoolId) -> 
	"online@"++ glib:to_str(SchoolId).


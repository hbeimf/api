% handler_account_info.erl

% /**
% 	 * 6> 账号基本信息 *
% 	 * http://m1.demo.com/api/accountInfo/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&uid=23&phone=15912345678
% 	 * school_id: 机构id
% 	 * mac: 设备mac
% 	 * token: 57f20f883e
% 	 */
-module(handler_account_info).

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
	{Uid, _} = cowboy_req:qs_val(<<"uid">>, Req2),
	{Phone, _} = cowboy_req:qs_val(<<"phone">>, Req2),
	{ok, Req4} = reply(Method, SchoolId, Mac, Token, Uid, Phone, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolId, _Mac, _Token, _Uid, _Phone, Req) when SchoolId =:= undefined orelse SchoolId =:= <<"">> ->
	Msg = unicode:characters_to_binary("机构编号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, Mac, _Token, _Uid,  _Phone, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, Token, _Uid,  _Phone, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolId, Mac, Token, Uid, Phone, Req) ->
             case logic:check_token(Token) of 
             	true -> 
             		case logic:has_activate(SchoolId, Mac) of 
             			true -> 
             				AccountUid = account_uid(Uid, Phone),
		  			case account_info(AccountUid) of
		  				error -> 
		  					Msg = unicode:characters_to_binary("账号不存在!! "),	
				             		Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
							Json = jsx:encode(Data),
							cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
		  				AccountInfo -> 
				             		Data = [{<<"flg">>, true}, {<<"msg">>, <<"">>}|AccountInfo],
							Json = jsx:encode(Data),
							cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
					end;
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

reply(_,  _SchoolId, _Mac, _Token, _Uid, _Phone, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


% priv fun ==============================

account_uid(Uid, Phone) when Uid =:= undefined orelse Uid =:= <<"">> ->
	Sql = "SELECT id FROM system_account WHERE account_name = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Phone]),
	case parse_res(Res) of
		{ok, []} -> 
			0;
		{ok, [Row|_]} ->
			{_, {_, Id}, _} = lists:keytake(<<"id">>, 1, Row),
			Id
	end;
account_uid(Uid, _Phone) -> 
	Uid.

account_info(Uid) -> 
	Info = account_info_teacher(Uid),
	parse_info(Info).

parse_info({ok, []}) ->
	error;
parse_info({ok, [Info]}) ->  
	 {_, {_, CourseType}, OtherInfo} = lists:keytake(<<"course_type">>, 1, Info),
	 lists:append(OtherInfo, [{<<"course_type">>, course_type(CourseType)}]).



account_info_teacher(Uid) -> 
	Sql = "SELECT a.account_id as uid, a.name, a.url, a.school_id, b.name as school_name, a.course_type
		FROM t_teacher as a 
		LEFT JOIN t_school_organization as b ON a.school_id = b.id 
		WHERE a.account_id = ? 
		LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Uid]),
	case parse_res(Res) of
		{ok, []} -> 
			account_info_student(Uid);
		Info ->
			Info
	end.

account_info_student(Uid) -> 
	Sql = "SELECT a.account_id as uid, a.name, a.url, a.school_id, b.name as school_name, a.course_type
		FROM t_student as a 
		LEFT JOIN t_school_organization as b ON a.school_id = b.id 
		WHERE a.account_id = ? 
		LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Uid]),
	parse_res(Res).


course_type(CourseType) ->
	Types = glib:explode(glib:to_str(CourseType), ","),
	% io:format("info: ~p~n", [{?MODULE, ?LINE, Types}]),
	lists:foldl(fun(Type, Res) -> 
		[types(Type)|Res]
	end, [], Types).

% public static $Type = [
%         [ 'id' =>'base',  'name' => '基础课'],
%         [ 'id' =>'characteristic',  'name' => '特色课'],
%         [ 'id' =>'interest',  'name' => '兴趣班'],
%         [ 'id' =>'level_examination',  'name' => '考级班'],
%     ];

types("base") -> 
	[{<<"type">>, <<"base">>}, {<<"name">>, unicode:characters_to_binary("基础课")}];
types("characteristic") -> 
	[{<<"type">>, <<"characteristic">>}, {<<"name">>, unicode:characters_to_binary("特色课")}];
types("interest") -> 
	[{<<"type">>, <<"interest">>}, {<<"name">>, unicode:characters_to_binary("兴趣班")}];
types("level_examination") -> 
	[{<<"type">>, <<"level_examination">>}, {<<"name">>, unicode:characters_to_binary("考级班")}].	

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(_Error) ->  
	{ok, []}.		

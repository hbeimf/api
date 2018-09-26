%% Feel free to use, reuse and abuse the code in this file.
% /**
% 	 *  1>激活接口 *
% 	 * http://m1.demo.com/api/activate/?SchoolName=测试机构&ContractNum=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
% 	
% 	http://localhost:8080/api/activate?school_name=测试机构&contract_num=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
% 	 * SchoolName: 机构名称
% 	 * ContractNum: 合同编号
% 	 * mac: 设备mac
% 	 * 设备首先得激活才能使用
% 	 */


%% @doc GET echo handler.
-module(handler_activate).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{Method, Req2} = cowboy_req:method(Req),
	{SchoolName, _} = cowboy_req:qs_val(<<"school_name">>, Req2),
	{ContractNum, _} = cowboy_req:qs_val(<<"contract_num">>, Req2),
	{Mac, _} = cowboy_req:qs_val(<<"mac">>, Req2),
	{Token, _} = cowboy_req:qs_val(<<"token">>, Req2),

	% io:format("params: ~p~n", [{SchoolName, ContractNum, Mac, Token}]),
	{ok, Req4} = reply(Method, SchoolName, ContractNum, Mac, Token, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolName,  _ContractNum, _Mac, _Token, Req) when SchoolName =:= undefined orelse SchoolName =:= <<"">> ->
	Msg = unicode:characters_to_binary("学校名称不对!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName,  ContractNum, _Mac, _Token, Req) when ContractNum =:= undefined orelse ContractNum =:= <<"">> ->
	Msg = unicode:characters_to_binary("合同编号不对!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName,  _ContractNum, Mac, _Token, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName,  _ContractNum, _Mac, Token, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolName, ContractNum, Mac, Token, Req) ->
	% Msg = unicode:characters_to_binary("参数不对!! "),

	% {ok, Config} = sys_config:get_config(api),
	 % {_, {host, Host}, _} = lists:keytake(host, 1, Config),
            % {_, {api_id, ApiId}, _} = lists:keytake(api_id, 1, Config),

             case logic:check_token(Token) of 
             	true -> 
             		case check(SchoolName, ContractNum) of 
             			true -> 
             				save_mac(Mac, ContractNum),
             				Msg = unicode:characters_to_binary("激活成功!! "),	
             				Data = [
						{<<"flg">>, true},
						{<<"msg">>, Msg},
						{<<"school_id">>, glib:to_integer(ContractNum)}
					],
					Json = jsx:encode(Data),
             				cowboy_req:reply(200, [
						{<<"content-type">>, <<"text/javascript; charset=utf-8">>}
					], Json, Req);
             			_ -> 

		             		Msg = unicode:characters_to_binary("机构名称合同编号有误!! "),	
		             		Data = [
						{<<"flg">>, false},
						{<<"msg">>, Msg}
					],
					Json = jsx:encode(Data),

					cowboy_req:reply(200, [
						{<<"content-type">>, <<"text/javascript; charset=utf-8">>}
					], Json, Req)
				end;
             	_ -> 
             		Msg = unicode:characters_to_binary("token 出错!! "),	
             		Data = [
				{<<"flg">>, false},
				{<<"msg">>, Msg}
			],
			Json = jsx:encode(Data),

			cowboy_req:reply(200, [
				{<<"content-type">>, <<"text/javascript; charset=utf-8">>}
			], Json, Req)
             end;

reply(_, _SchoolName, _ContractNum, _Mac, _Token, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


% priv fun ==============================

check(SchoolName, ContractNum) -> 
	Sql = "SELECT count(*) as c FROM t_school_organization WHERE id = ? AND name = ?",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [glib:to_integer(ContractNum), SchoolName]),
	Row = parse_res(Res),
	check_num(Row).

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(Error) ->  
	Error.		


check_num({ok, [[{_, Num}]]}) when Num > 0 ->
	true;
check_num(_) ->  
	false.

save_mac(Mac, SchoolId) ->
	Sql = "SELECT count(*) as c FROM t_mac WHERE mac = ?",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Mac]),
	Row = parse_res(Res),

	case check_num(Row) of
		false ->
			Time = glib:time(),
			SqlInsert = "INSERT INTO `t_mac` (`mac`, `school_id`, `created_at`, `updated_at`) VALUES (?,?,?,?)",
			ParamsList = [glib:to_str(Mac), glib:to_integer(SchoolId), Time, Time],
			mysql_poolboy:query(mysqlc:pool(), SqlInsert, ParamsList),
			ok;
		_ -> 
			Time = glib:time(),
			SqlUpdate = "UPDATE `t_mac` SET school_id = ?, updated_at = ? WHERE mac = ?",
			ParamsList = [glib:to_integer(SchoolId), Time, Mac],
			mysql_poolboy:query(mysqlc:pool(), SqlUpdate, ParamsList),
			ok
	end.

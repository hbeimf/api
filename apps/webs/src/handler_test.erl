%% Feel free to use, reuse and abuse the code in this file.
% /**
% 	 *  1>激活接口 *
% 	 * http://m1.demo.com/api/activate/?SchoolName=测试机构&ContractNum=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
% 	
% 	http://localhost:8080/api/test?school_name=测试机构&contract_num=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
% http://m2.demo.com/api/test?school_name=测试机构&contract_num=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
% 	 * SchoolName: 机构名称
% 	 * ContractNum: 合同编号
% 	 * mac: 设备mac
% 	 * 设备首先得激活才能使用
% 	 */


%% @doc GET echo handler.
-module(handler_test).

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

reply(<<"GET">>, SchoolName,  _ContractNum, _Mac, _Token, Req) when SchoolName =:= undefined ->
	Msg = unicode:characters_to_binary("学校名称不对!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName,  ContractNum, _Mac, _Token, Req) when ContractNum =:= undefined ->
	Msg = unicode:characters_to_binary("合同编号不对!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName,  _ContractNum, Mac, _Token, Req) when Mac =:= undefined ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName,  _ContractNum, _Mac, Token, Req) when Token =:= undefined ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolName, _ContractNum, _Mac, _Token, Req) ->
	Msg = unicode:characters_to_binary("参数不对!! "),

	{ok, Config} = sys_config:get_config(api),
	 % {_, {host, Host}, _} = lists:keytake(host, 1, Config),
            {_, {api_id, ApiId}, _} = lists:keytake(api_id, 1, Config),

	Data = [
		{<<"flg">>, true},
		{<<"msg">>, Msg},
		{<<"api_id">>, ApiId}
	],
	Json = jsx:encode(Data),

	cowboy_req:reply(200, [
		{<<"content-type">>, <<"text/javascript; charset=utf-8">>}
	], Json, Req);
	
reply(_, _SchoolName, _ContractNum, _Mac, _Token, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.

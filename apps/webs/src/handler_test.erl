%% Feel free to use, reuse and abuse the code in this file.
% http://localhost:8088/api/test
%% @doc GET echo handler.
-module(handler_test).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{Method, Req2} = cowboy_req:method(Req),
	{ok, Req4} = reply(Method, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, Req) ->
	Msg = unicode:characters_to_binary("测试!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
	
reply(_, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(400, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.

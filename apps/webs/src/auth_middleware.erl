-module(auth_middleware).
-behaviour(cowboy_middleware).

-export([execute/2]).

% https://www.cnblogs.com/ziyouchutuwenwu/p/4278069.html

%% 这个是回调函数
execute(Req, Env) ->
	{PathInfo,_} = cowboy_req:path(Req),
	Path = binary_to_list(PathInfo),
	io:format("Path is ~p~n",[Path]),
	exe(Path, Req, Env).


exe("/api/user/login", Req, Env) -> 
	{ok, Req, Env};
exe(_, Req, Env) ->
    	case cowboy_req:parse_header(<<"authorization">>, Req) of 
		{ok , {_,  Token}, _} -> 
			% io:format("~p~n", [Token]),
			Key = <<"supas3cri7">>,
			R = jwt:decode(Token, Key),
			io:format("~p~n", [R]),

			{ok, Req, Env};
		R ->
			io:format("~p~n", [<<"no login">>]),
			Msg = unicode:characters_to_binary("没登录!! "),
			Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
			Json = jsx:encode(Data),
			cowboy_req:reply(400, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req),
			% {shutdown, Req, <<"Unauthorization">>}

			{halt, Req} 
	end.
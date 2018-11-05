%%%-------------------------------------------------------------------
%% @doc webs public API
%% @end
%%%-------------------------------------------------------------------

-module(webs_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/login", handler_login, []},
			{"/api/admin/refresh_token", handler_refresh_token, []},
			{"/websocket", handler_ws, []}
		]}
	]),

	{ok, Config} = sys_config:get_config(http),
	 % {_, {host, Host}, _} = lists:keytake(host, 1, Config),
            {_, {port, Port}, _} = lists:keytake(port, 1, Config),

	{ok, _} = cowboy:start_http(http, 100, [{port, Port}], 
		[{env, [{dispatch, Dispatch}]}, {middlewares, [cowboy_router, auth_middleware, cowboy_handler]}]),
		
    webs_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

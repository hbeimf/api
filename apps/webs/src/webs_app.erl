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
			{"/api/test", handler_test, []},
			{"/api/activate", handler_activate, []},
			{"/api/login", handler_login, []},
			{"/api/modifyPasswd", handler_modify_password, []},
			{"/api/curriculumList", handler_curriculum_list, []},
			{"/api/curriculumInfo", handler_curriculum_info, []},
			{"/api/studentList", handler_student_list, []},
			{"/api/calssList", handler_class_list, []},
			{"/api/accountInfo", handler_account_info, []}
		]}
	]),

	{ok, Config} = sys_config:get_config(http),
	 % {_, {host, Host}, _} = lists:keytake(host, 1, Config),
            {_, {port, Port}, _} = lists:keytake(port, 1, Config),

	{ok, _} = cowboy:start_http(http, 100, [{port, Port}],
		[{env, [{dispatch, Dispatch}]}]),
		
    webs_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

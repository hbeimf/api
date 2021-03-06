%%%-------------------------------------------------------------------
%% @doc mysqlc public API
%% @end
%%%-------------------------------------------------------------------

-module(mysqlc_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    mysqlc_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

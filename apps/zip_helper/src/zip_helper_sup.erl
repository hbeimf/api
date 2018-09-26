%%%-------------------------------------------------------------------
%% @doc zip_helper top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(zip_helper_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
	MakeZip = {zip_helper_server, {zip_helper_server, start_link, []},
               permanent, 5000, worker, [zip_helper_server]},

                   Children = [MakeZip],
    	{ok, { {one_for_all, 0, 1}, Children} }.

%%====================================================================
%% Internal functions
%%====================================================================

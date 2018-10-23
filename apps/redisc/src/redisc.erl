-module(redisc).
-compile(export_all).

test() -> 
	set(),
	redisc_get().

redisc_get() ->
    redisc_get("foo").
redisc_get(Key) ->
    redisc_call:q(pool_redis, ["GET", Key]).

set() ->
    set("foo", "bar").
set(Key, Val) ->
    redisc_call:q(pool_redis, ["SET", Key, Val]).

get() ->
    redisc:get("foo").
get(Key) ->
    redisc_call:q(pool_redis, ["GET", Key]).
    
hget() -> 
    Hash = "info@341659",
    A = hget(Hash, "gold"),
    B = hgetall(Hash),
    {A, B}.

hget(Hash, Key) -> 
    q(["hget", Hash, Key], 3000).

hgetall(Hash) -> 
    redisc_call:q(pool_redis, ["hgetall", Hash]).
    
hset(Hash, Key, Val) ->
    q(["hset", Hash, Key, Val], 3000). 

pub() ->
    pub('test-channel', <<"hello world!!">>).
pub(Chan, Msg) ->
    q(["PUBLISH", Chan, Msg]).

sub() ->
    sub(['test-channel']).
sub(Channels) ->
    {ok, Sub} = eredis_sub:start_link("127.0.0.1", 6379, ""),
    spawn(fun() -> 
        loop(Sub, Channels)
    end).
       

loop(Sub, Channels) -> 
     ok = eredis_sub:controlling_process(Sub),
    ok = eredis_sub:subscribe(Sub, Channels),
    lists:foreach(
      fun (C) ->
              receive 
                    {subscribed, _, _} -> 
                         loop(Sub, Channels);
                    M ->
                      % ?assertEqual({subscribed, C, Sub}, M),
                      io:format("msg:~p~n", [M]),
                      eredis_sub:ack_message(Sub),
                      loop(Sub, Channels)
                    
              end
      end, Channels).



q(Command) -> 
    redisc_call:q(pool_redis, Command).
q(Command, Timeout) -> 
    redisc_call:q(pool_redis, Command, Timeout).


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

q(Command) -> 
    redisc_call:q(pool_redis, Command).
q(Command, Timeout) -> 
    redisc_call:q(pool_redis, Command, Timeout).


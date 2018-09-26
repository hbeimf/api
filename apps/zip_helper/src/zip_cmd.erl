-module(zip_cmd).
-compile(export_all).
-include("state.hrl").

sync() -> 
	{Dir, BakDir} = mkdir(),
	Cmd = lists:concat(["scp -r root@47.106.78.218:", Dir, ".tar.gz /root/bak/"]),
	io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, Cmd]),	
	os:cmd(Cmd),
	ok.

bak() -> 
	{Dir, BakDir} = mkdir(),
	bak_nginx(Dir),
	bak_mysql(Dir),
	bak_code(Dir),
	tar(Dir, BakDir),
	clean(),
	ok.

clean() -> 
	BaseDir = base_dir(),
	lists:foreach(fun(I) -> 
		Time = glib:time() - 24 * 60 * 60 * I,
		{{Year, Month, Day},{_Hour, _Min, _Second}} = glib:timestamp_to_datetime(Time),
		BakDir = lists:concat([BaseDir, "/", Year, Month, Day, ".tar.gz"]),
		Cmd = lists:concat(["rm -rf ", BakDir]),
		io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, Cmd]),	
		os:cmd(Cmd),
		% ?LOG(R),
		ok
	end, lists:seq(5, 8)),
	ok.


% tar czvf bak201844.tar.gz -C /mnt/bak bak201844
% tar czvf /mnt/bak/bak201844.tar.gz -C /mnt/bak/ bak201844

tar(Dir, BakDir) -> 
	CDir = glib:replace(Dir, BakDir, ""),
	CmdList = [
		lists:concat(["tar czvf ", Dir, ".tar.gz -C ", CDir, " ", BakDir]),
		lists:concat(["rm -rf ", Dir])
	],
	lists:foreach(fun(Cmd) -> 
		io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, Cmd]),	
		os:cmd(Cmd)
	end, CmdList).

bak_code(Dir) ->
	Cmd = lists:concat(["cp /mnt/web/m.demo.com ", Dir, "/ -R"]),
	io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, Cmd]),
	os:cmd(Cmd),
	ok. 

bak_mysql(Dir) -> 
	case sys_config:get_config(mysql) of 
		{ok, MysqlConfig} -> 
			{_, {host, Host}, _} = lists:keytake(host, 1, MysqlConfig),
			% {_, {port, Port}, _} = lists:keytake(port, 1, MysqlConfig),
			{_, {user, User}, _} = lists:keytake(user, 1, MysqlConfig),
			{_, {password, Password}, _} = lists:keytake(password, 1, MysqlConfig),
			{_, {database, Database}, _} = lists:keytake(database, 1, MysqlConfig),	

			% Cmd = lists:concat(["mysqldump -u", "root",  "-p", "123456",  "-h", "127.0.0.1", "  system > ", Dir, "/system.sql"]),
			Cmd = lists:concat(["mysqldump -u", User,  " -p", Password,  " -h", Host, "  ", Database, " > ", Dir, "/", Database, ".sql"]),
 			io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, Cmd]),
 			os:cmd(Cmd),
			ok;
		_ -> 
			ok
	end.

bak_nginx(Dir) -> 
	CmdList = [
		lists:concat(["cp /usr/local/nginx/conf/nginx.conf ", Dir, "/"]),
		lists:concat(["cp /usr/local/nginx/conf/vhost/*.conf ", Dir, "/"])
	],
	lists:foreach(fun(Cmd) -> 
		io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, Cmd]),	
		os:cmd(Cmd)
	end, CmdList).

mkdir() -> 
	{{Year, Month, Day},{_Hour, _Min, _Second}} = erlang:localtime(),
	BakDir = lists:concat([base_dir(), "/bak", Year, Month, Day]),
	mkdir("/mnt/bak"),
	mkdir(BakDir),
	{BakDir, lists:concat(["bak", Year, Month, Day])}.
	% io:format("mod:~p, line:~p ============~n ~p~n~n", [?MODULE, ?LINE, BakDir]),
	% ok.

mkdir(Dir) -> 
	case glib:is_dir(Dir) of 
		true -> 
			ok;
		_ -> 
			glib:make_dir(Dir)
	end.

base_dir() -> 
	"/mnt/bak".

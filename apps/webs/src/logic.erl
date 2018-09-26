-module(logic).
-compile(export_all).


% 请求时token判断 
check_token(Token) ->
	Token1 = glib:to_str(Token),
	{ok, Config} = sys_config:get_config(api),
	
            case lists:keytake(token, 1, Config) of
            		{_, {token, Token1}, _} ->
            			true;
            		_ -> 
            			false
            	end.	

% 判断设备是否激活
has_activate(SchoolId, Mac) -> 
	Sql = "SELECT id FROM t_mac where school_id = ? AND mac = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [SchoolId, Mac]),
	case parse_res(Res) of 
		{ok, []} -> 
			false;
		{ok, _RowList} ->
			true;
		_ -> 
			false
	end.

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(_Error) ->  
	{ok, []}.	


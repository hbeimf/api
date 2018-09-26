% /**
% 	 * 2>登录接口 *
% 	 * http://m1.demo.com/api/login/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15923565897&password=123456
 % http://m2.demo.com/api/login/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15923565897&password=123456
% 	 * school_id: 机构id
% 	 * mac: 设备mac
% 	 * username: 用户名
% 	 * password: 口令
% 	 * token:
% 	 * 设备登录后连接代理服，代理服进程身份验证
% 	 */


% ：您的账号已被暂时禁用，请联系客服


-module(handler_login).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{Method, Req2} = cowboy_req:method(Req),
	{SchoolId, _} = cowboy_req:qs_val(<<"school_id">>, Req2),
	{Mac, _} = cowboy_req:qs_val(<<"mac">>, Req2),
	{Token, _} = cowboy_req:qs_val(<<"token">>, Req2),
	{UserName, _} = cowboy_req:qs_val(<<"username">>, Req2),
	{Password, _} = cowboy_req:qs_val(<<"password">>, Req2),
	{ok, Req4} = reply(Method, SchoolId, Mac, Token, UserName, Password, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolId, _Mac, _Token, _UserName, _Password, Req) when SchoolId =:= undefined orelse SchoolId =:= <<"">> ->
	Msg = unicode:characters_to_binary("机构编号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, Mac, _Token, _UserName, _Password, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, Token, _UserName, _Password, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, _Token, UserName, _Password, Req) when UserName =:= undefined orelse UserName =:= <<"">> ->
	Msg = unicode:characters_to_binary("账号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
% reply(<<"GET">>, _SchoolId, _Mac, _Token, _UserName, Password, Req) when Password =:= undefined orelse Password =:= <<"">> ->
% 	Msg = unicode:characters_to_binary("口令有误!! "),
% 	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
% 	Json = jsx:encode(Data),
% 	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolId, Mac, Token, UserName, Password, Req) ->
             case logic:check_token(Token) of 
             	true -> 
             		case logic:has_activate(SchoolId, Mac) of 
             			true -> 
		             		AccountId = select_account_id(UserName, Password),
		             		case AccountId > 0 of
		             			true -> 
		             				case account_info(AccountId) of
		             					error -> 
				             				Msg = unicode:characters_to_binary("账号口令有误!! "),	
						             		Data = [{<<"flg">>, true},{<<"msg">>, Msg}],
									Json = jsx:encode(Data),
									cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
								Info -> 
									{_, {_, Name}, _} = lists:keytake(<<"name">>, 1, Info),
									{_, {_, Url}, _} = lists:keytake(<<"url">>, 1, Info),
									{_, {_, Phone}, _} = lists:keytake(<<"phone">>, 1, Info),

									% Domain = domain(),
									% Url1 = lists:concat([glib:to_str(domain()), glib:to_str(Url)]),


									RToken = token(),
									% 设置token
									redisc:hset(glib:to_binary("userinfo@"++glib:to_str(AccountId)), <<"token">>, RToken),
									
									{ProxyIp, ProxyPort} = proxy(),

									RoleId = role_id(AccountId, UserName),
						             		Data = [{<<"flg">>, true}, {<<"msg">>, <<"">>}, {<<"uid">>, AccountId},
										{<<"name">>, Name},{<<"phone">>, Phone}, {<<"pic_url">>, Url}, {<<"token">>, RToken},
										{<<"ip">>, ProxyIp},{<<"port">>, ProxyPort}, {<<"role_id">>, RoleId}],
									Json = jsx:encode(Data),
									cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
							end;
		             				% ok;
		             			_ -> 

							Msg = unicode:characters_to_binary("账号口令有误!! "),	
				             		Data = [{<<"flg">>, false},{<<"msg">>, Msg}],
							Json = jsx:encode(Data),
							cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
					end;
				_ -> 
					Msg = unicode:characters_to_binary("设备未激活!! "),	
		             		Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
					Json = jsx:encode(Data),
					cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
			end;

             	_ -> 
             		Msg = unicode:characters_to_binary("token 出错!! "),	
             		Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
			Json = jsx:encode(Data),
			cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req)
             end;

reply(_, _SchoolId, _Mac, _Token, _UserName, _Password, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


% priv fun ==============================
domain() -> 
	case sys_config:get_config(htgl) of
		{ok, Config} -> 
			{_, {domain, Domain}, _} = lists:keytake(domain, 1, Config),
			Domain;
		_ -> 
			<<"">>
	end.


proxy() -> 
% 	{<<"127.0.0.1">>, 9900}.
    case  sys_config:get_config(proxy) of
        {ok, Proxy} -> 
            {_, {host, Host}, _} = lists:keytake(host, 1, Proxy),
            {_, {port, Port}, _} = lists:keytake(port, 1, Proxy),
            {glib:to_binary(Host), Port};
        _ -> 
            {<<"127.0.0.1">>, 9900}
    end.

token() ->
	T = glib:md5(glib:to_str(glib:uid())),
	B = glib:to_binary(T),
	binary:part(B, 0, 10).

account_info(AccountId) ->
	% concat("http://www.baidu.com", dir)
	Domain = domain(),
	Sql = "SELECT name, phone, concat(?, dir) as url FROM t_teacher where account_id = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Domain, AccountId]),
	case parse_res(Res) of 
		{ok, []} -> 
			account_info_student(AccountId);
		{ok, [Row]} ->
			info(Row);
		_ -> 
			account_info_student(AccountId)	
	end.

account_info_student(AccountId) -> 
	Domain = domain(),
	Sql = "SELECT name, phone, concat(?, dir)as url FROM t_student where account_id = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [Domain, AccountId]),
	case parse_res(Res) of 
		{ok, []} -> 
			error;
		{ok, [Row]} ->
			info(Row);
		_ -> 
			error
	end.

info(Row) ->
	Row. 


select_account_id(UserName, Password)  when Password =:= undefined orelse Password =:= <<"">> -> 
	%% 必须是学生账号才允许免密码登录 
	Sql = "SELECT id FROM system_account WHERE account_name = ? AND status = 1 LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [UserName]),
	List = parse_res(Res),
	UserId = parse_id(List),
	%% 如果是学生才返回正常的UserId,
	case role_id(UserId, UserName) of
		0 -> 
			UserId;
		_ ->
			0
	end;
select_account_id(UserName, Password) -> 
	% Sql = "SELECT id FROM system_account WHERE account_name = ? AND passwd = ? LIMIT 1",
	Sql = "SELECT id FROM system_account WHERE account_name = ? AND status = 1 LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [UserName]),
	List = parse_res(Res),
	% io:format("account: ~p~n", [{?MODULE, ?LINE, List}]),
	parse_id(List).
	% check_num(Row).  

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(_Error) ->  
	{ok, []}.		

parse_id({ok, []}) ->
	0;
parse_id({ok, [[{_, Id}|_]|_]}) ->
	Id;
parse_id(_) -> 
	0.


% role_id(UserId) ->
%     mysqlc:role_id(UserId).


% role_id() -> 
%     role_id(23).
%% 学生返回 0 ， 老师返回 1, 其它返回 2
role_id(UserId, UserName) -> 
     Sql = "SELECT id, account_id FROM t_student WHERE account_id = ? AND phone = ? LIMIT 1",
     Res = mysql_poolboy:query(mysqlc:pool(), Sql, [UserId, UserName]),
     case parse_res(Res) of 
        {ok, []} ->
            role_teacher(UserId, UserName);
        _ ->
        	%% 学生
            0
    end.

%% 老师返回 1, 其它返回 2
role_teacher(UserId, UserName) -> 
     Sql = "SELECT id, account_id FROM t_teacher WHERE account_id = ? AND phone = ? LIMIT 1",
     Res = mysql_poolboy:query(mysqlc:pool(), Sql, [UserId, UserName]),
     case parse_res(Res) of 
        {ok, []} ->
        	%% 其它
            2;
        _ ->
        	%% 老师
            1
    end.
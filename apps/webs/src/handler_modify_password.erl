% /**
% 	 * 2.1>修改密码
% 	 * http://m1.demo.com/api/modifyPasswd/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15923565897&oldpassword=123456&newpassword=123456
%  http://m2.demo.com/api/modifyPasswd/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15923565897&oldpassword=123456&newpassword=123456
% 	 * school_id: 机构id
% 	 * mac: 设备mac
% 	 * username: 用户名
% 	 * oldpassword: 旧口令
% 	 * newpassword : 新口令
% 	 * token:
% 	 * 设备登录后连接代理服，代理服进程身份验证
% 	 */

-module(handler_modify_password).

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
	% username
	{Username, _} = cowboy_req:qs_val(<<"username">>, Req2),
	{OldPassword, _} = cowboy_req:qs_val(<<"oldpassword">>, Req2),
	{NewPassword, _} = cowboy_req:qs_val(<<"newpassword">>, Req2),
	
	{ok, Req4} = reply(Method, SchoolId, Mac, Token, Username, OldPassword, NewPassword, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolId, _Mac, _Token, _Username,  _OldPassword, _NewPassword, Req) when SchoolId =:= undefined orelse SchoolId =:= <<"">> ->
	Msg = unicode:characters_to_binary("机构编号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, Mac, _Token, _Username, _OldPassword, _NewPassword, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, Token, _Username, _OldPassword, _NewPassword, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, _Token, Username, _OldPassword, _NewPassword, Req) when Username =:= undefined orelse Username =:= <<"">> ->
	Msg = unicode:characters_to_binary("账号名出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, _Token, _Username,  OldPassword, _NewPassword, Req) when OldPassword =:= undefined orelse OldPassword =:= <<"">> ->
	Msg = unicode:characters_to_binary("原口令有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, _Token, _Username, _OldPassword, NewPassword, Req) when NewPassword =:= undefined orelse NewPassword =:= <<"">> ->
	Msg = unicode:characters_to_binary("新口令有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolId, Mac, Token, Username, OldPassword, NewPassword, Req) ->
             case logic:check_token(Token) of 
             	true -> 
             		case logic:has_activate(SchoolId, Mac) of 
             			true -> 
		  			% 修改口令
		  			AccountId = select_account_id(Username, OldPassword),
		  			case AccountId > 0 of 
		  				true -> 
		  					update_account_password(AccountId, NewPassword),
		  					Msg = unicode:characters_to_binary("修改成功!! "),	
				             		Data = [{<<"flg">>, true}, {<<"msg">>, Msg}],
							Json = jsx:encode(Data),
							cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
		  				_ -> 
							Msg = unicode:characters_to_binary("账号口令有误!! "),	
				             		Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
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

reply(_,  _SchoolId, _Mac, _Token, _Username, _OldPassword, _NewPassword, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


% priv fun ==============================
 
update_account_password(AccountId, NewPassword) ->
	Time = glib:time(),
	SqlUpdate = "UPDATE `system_account` SET passwd = ?, updated_at = ? WHERE id = ?",
	ParamsList = [glib:md5(NewPassword), Time, AccountId],
	mysql_poolboy:query(mysqlc:pool(), SqlUpdate, ParamsList),
	ok.		


select_account_id(UserName, Password) -> 
	Sql = "SELECT id FROM system_account WHERE account_name = ? AND passwd = ? LIMIT 1",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, [UserName, glib:md5(Password)]),
	List = parse_res(Res),
	parse_id(List).

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(Error) ->  
	Error.		

parse_id({ok, []}) ->
	0;
parse_id({ok, [[{_, Id}|_]|_]}) ->
	Id;
parse_id(_) -> 
	0.

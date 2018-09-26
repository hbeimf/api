% /**
%  * 3> 课程列表
%  * http://m1.demo.com/api/curriculumList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
% http://m2.demo.com/api/curriculumList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
%  * school_id: 机构id
%  * mac: 设备mac
%  * token:
%  */

-module(handler_curriculum_list).

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
	{ok, Req4} = reply(Method, SchoolId, Mac, Token, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, SchoolId, _Mac, _Token, Req) when SchoolId =:= undefined orelse SchoolId =:= <<"">> ->
	Msg = unicode:characters_to_binary("机构编号有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, Mac, _Token, Req) when Mac =:= undefined orelse Mac =:= <<"">> ->
	Msg = unicode:characters_to_binary("物理地址有误!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, _SchoolId, _Mac, Token, Req) when Token =:= undefined orelse Token =:= <<"">> ->
	Msg = unicode:characters_to_binary("token 出错!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
reply(<<"GET">>, SchoolId, Mac, Token, Req) ->
             case logic:check_token(Token) of 
             	true -> 
             		case logic:has_activate(SchoolId, Mac) of 
             			true -> 
		  			case  select_curriculum_list() of
		  				{ok, CurriculumList} ->
		  					Data = [{<<"flg">>, true}, {<<"msg">>, <<"">>}, {<<"data">>, CurriculumList}],
							Json = jsx:encode(Data),
							cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
		  				_ -> 
							Msg = unicode:characters_to_binary("暂时未设置任何课程，请耐心等待!! "),	
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

reply(_,  _SchoolId, _Mac, _Token, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


% priv fun ==============================
 
% select_curriculum_list() -> 

select_curriculum_list() -> 
	Sql = "SELECT id, order_by as show_id,  name FROM t_curriculum WHERE is_enabled = 1 ORDER BY order_by DESC",
	Res = mysql_poolboy:query(mysqlc:pool(), Sql, []),
	parse_res(Res).

parse_res({ok, KeyList, DataList}) -> 
	RowList = lists:foldl(fun(Data, Res) -> 
		T = lists:zip(KeyList, Data),
		[T|Res]
	end, [], DataList),
	{ok, RowList};
parse_res(Error) ->  
	Error.		

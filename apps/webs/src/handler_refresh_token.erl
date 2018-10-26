%% Feel free to use, reuse and abuse the code in this file.
% http://localhost:8088/api/test
%% @doc GET echo handler.
-module(handler_refresh_token).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).
-include("log.hrl").

init(_Transport, Req, []) ->
	io:format("~p~n", [init ]),
	{ok, Req, undefined}.

handle(Req, State) ->
	{Method, Req2} = cowboy_req:method(Req),
	{ok, Req4} = reply(Method, Req2),
	{ok, Req4, State}.

reply(<<"GET">>, Req) ->

	Key = <<"supas3cri7">>,
	Claims = [
		{user_id, 42},
		{user_name, <<"Bob">>}
	],
	% {ok, Token} = jwt:encode(<<"HS256">>, Claims, Key),
	% or with expiration
	ExpirationSeconds = 86400,
	{ok, Token} = jwt:encode(<<"HS256">>, Claims, ExpirationSeconds, Key),
	% Parse JWT token
	% {ok, Claims} = jwt:decode(Token, Key).

	Msg = unicode:characters_to_binary("刷新token!! "),
	% Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}, {<<"token">>, Token}],

	% rsa_test(),
	glibrsa:test(),

	Json = jsx:encode(Data),
	cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req);
	
reply(_, Req) ->
	%% Method not allowed.
	Msg = unicode:characters_to_binary("接口不存在!! "),
	Data = [{<<"flg">>, false}, {<<"msg">>, Msg}],
	Json = jsx:encode(Data),
	cowboy_req:reply(400, [{<<"content-type">>, <<"text/javascript; charset=utf-8">>}], Json, Req).

terminate(_Reason, _Req, _State) ->
	ok.


%% rsa test 
% rsa_test() ->
% 	test(<<"hello world . hhhhhhhhh!!!">>),
% 	% test_crypty(),
% 	ok.



% rsa_public_encrypt(PlainText, PublicKey, Padding) -> ChipherText
% rsa_private_decrypt(ChipherText, PrivateKey, Padding) -> PlainText
% rsa_private_encrypt(PlainText, PrivateKey, Padding) -> ChipherText
% rsa_public_decrypt(ChipherText, PublicKey, Padding) -> PlainText
% Padding = rsa_pkcs1_padding | rsa_no_padding

% test_crypty() -> 
% 	PlainText = <<"hello world!!!">>,
% 	ChipherText = crypto:rsa_public_encrypt(PlainText, rsa_public_key(), rsa_no_padding), % -> ChipherText
% 	?LOG({encode, ChipherText}),
% 	% PlainText1 = crypto:rsa_private_decrypt(ChipherText, rsa_private_key(), rsa_no_padding), % -> PlainText
% 	% ?LOG({decode, PlainText1}),
% 	ok.



% % ====================================
% read_rsa_key(FileName) ->
%     {ok, PemBin} = file:read_file(FileName),
%     [Entry] = public_key:pem_decode(PemBin),
%     public_key:pem_entry_decode(Entry).

% rsa_public_key() ->
% 	PubKeyFile = root_dir() ++ "config/publickey.key",
%     read_rsa_key(PubKeyFile).

% rsa_private_key() ->
% 	PriKeyFile = root_dir() ++ "config/privatekey.key",
%     read_rsa_key(PriKeyFile).

% enc(PlainText) ->
%     public_key:encrypt_public(PlainText, rsa_public_key()).

% dec(CipherText)->
%     public_key:decrypt_private(CipherText, rsa_private_key()).

% test(Msg) ->
%     CipherText = enc(Msg),
% 	Base64 = base64:encode_to_string(CipherText),
%     ?LOG({encode, Msg, CipherText, Base64}),
%     PlainText = dec(CipherText),
%     ?LOG({decode, PlainText, glib:to_binary(base64:decode_to_string(Base64))}).


% % private functions
% root_dir() ->
% 	replace(os:cmd("pwd"), "\n", "/"). 

% replace(Str, SubStr, NewStr) ->
% 	case string:str(Str, SubStr) of
% 		Pos when Pos == 0 ->
% 			Str;
% 		Pos when Pos == 1 ->
% 			Tail = string:substr(Str, string:len(SubStr) + 1),
% 			string:concat(NewStr, replace(Tail, SubStr, NewStr));
% 		Pos ->
% 			Head = string:substr(Str, 1, Pos - 1),
% 			Tail = string:substr(Str, Pos + string:len(SubStr)),
% 			string:concat(string:concat(Head, NewStr), replace(Tail, SubStr, NewStr))
% 	end.
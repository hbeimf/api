-module(glibrsa).
% -compile(export_all).
-export([encode/1, decode/1, test/0, test/1]).
-include_lib("webs/include/log.hrl").
% ====================================
read_rsa_key(FileName) ->
    {ok, PemBin} = file:read_file(FileName),
    [Entry] = public_key:pem_decode(PemBin),
    public_key:pem_entry_decode(Entry).

rsa_public_key() ->
	PubKeyFile = root_dir() ++ "config/publickey.key",
    read_rsa_key(PubKeyFile).

rsa_private_key() ->
	PriKeyFile = root_dir() ++ "config/privatekey.key",
    read_rsa_key(PriKeyFile).

encode(Str) ->
 Bin =  public_key:encrypt_public(Str, rsa_public_key()),
base64:encode_to_string(Bin).


decode(Base64)->
   Bin = glib:to_binary(base64:decode_to_string(Base64)),
    public_key:decrypt_private(Bin, rsa_private_key()).

test() ->
    Msg = <<"test!">>,
    test(Msg).
test(Msg) ->
	R = encode(Msg),
	?LOG({encode, R}),
	R1 = decode(R),
	?LOG({decode, R1}),
	ok.


% private functions
root_dir() ->
	replace(os:cmd("pwd"), "\n", "/"). 

replace(Str, SubStr, NewStr) ->
	case string:str(Str, SubStr) of
		Pos when Pos == 0 ->
			Str;
		Pos when Pos == 1 ->
			Tail = string:substr(Str, string:len(SubStr) + 1),
			string:concat(NewStr, replace(Tail, SubStr, NewStr));
		Pos ->
			Head = string:substr(Str, 1, Pos - 1),
			Tail = string:substr(Str, Pos + string:len(SubStr)),
			string:concat(string:concat(Head, NewStr), replace(Tail, SubStr, NewStr))
	end.











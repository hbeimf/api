-module(glibaes).
% -compile(export_all).
-export([encode/1, decode/1, test/0, test/1]).
-include_lib("webs/include/log.hrl").

% application:start(crypto).

% 注意： Key, IVec, PlainText 必须都为128比特，也就是16字节
test() -> 
	Str = <<"abcdefgasdfghjkd">>,
	test(Str).
test(Str) ->
	Bin = encode(Str),
	?LOG({encode, Bin}),
	R = decode(Bin),
	?LOG({decode, R}),
	ok.


encode(Str) ->
	CipherText = crypto:block_encrypt(type(), key(), ivec(), Str).

decode(Bin) ->
	crypto:block_decrypt(type(), key(), ivec(), Bin).

ivec() -> 
	<<0:128>>.

type() -> 
	aes_cbc128.

key() -> 
	<<"asdfghkl;'][poi?">>.

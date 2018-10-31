package controller

import (
	"github.com/goerlang/etf"
	"log"

	"../aes256"
)

// ================================================================
type Aes256Controller struct {
	// Controller
}

func (this *Aes256Controller) Excute(message etf.Tuple) *etf.Term {
	log.Printf("message aes256 : %#v", message)

	encode_or_decode := message[1].(etf.Atom)

	str := message[2].(string)
	password := message[3].(string)
	log.Printf("message key : %#v", password)
	log.Printf("message str : %#v", str)

	if string(encode_or_decode) == "encode" {
		reply := aes256.Encrypt(str, password)
		replyTuple := etf.Tuple{etf.Atom("ok"), reply}
		replyTerm := etf.Term(replyTuple)
		return &replyTerm
	} else {
		reply := aes256.Decrypt(str, password)
		replyTuple := etf.Tuple{etf.Atom("ok"), reply}
		replyTerm := etf.Term(replyTuple)
		return &replyTerm
	}
}

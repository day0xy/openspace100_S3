// Package main -----------------------------
// @file      : main.go
// @author    : day0xy
// @time      : 7/2/24
// -------------------------------------------
package main

import (
	"crypto/sha256"
	"fmt"
	"strings"
)

func findHashWithPrefix(nickname string, prefix string) (int, string, string) {
	nonce := 0

	//无限循环找nonce
	for {
		//fmt.Sprintf可以存储到变量中
		data := fmt.Sprintf("%s%d", nickname, nonce)
		hash := sha256.Sum256([]byte(data))
		hashHex := fmt.Sprintf("%x", hash)

		if strings.HasPrefix(hashHex, prefix) {
			return nonce, data, hashHex
		}
		nonce++
	}

}

func main() {
	nickname := "day0xy"
	nonce, data, hashHex := findHashWithPrefix(nickname, "0000")
	fmt.Printf("4 zero:\nnonce: %d\ndata: %s\nhashHex: %s\n\n", nonce, data, hashHex)
	nonce, data, hashHex = findHashWithPrefix(nickname, "00000")
	fmt.Printf("5 zero:\nnonce: %d\ndata: %s\nhashHex: %s\n", nonce, data, hashHex)
}

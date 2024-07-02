// Package main -----------------------------
// @file      : 1.go
// @author    : day0xy
// @time      : 7/2/24
// -------------------------------------------
package main

import (
	"crypto/sha256"
	"fmt"
	"strings"
	"time"
)

func findHashWithPrefix(nickname string, prefix string) (int, string, string, time.Duration) {
	nonce := 0
	start := time.Now()

	//无限循环找nonce
	for {
		//fmt.Sprintf可以存储到变量中
		data := fmt.Sprintf("%s%d", nickname, nonce)
		hash := sha256.Sum256([]byte(data))
		hashHex := fmt.Sprintf("%x", hash)

		if strings.HasPrefix(hashHex, prefix) {
			elapsed := time.Since(start)
			return nonce, data, hashHex, elapsed
		}
		nonce++
	}

}

func main() {
	nickname := "day0xy"
	nonce, data, hashHex, elapsed := findHashWithPrefix(nickname, "0000")
	fmt.Printf("4 zero:\nnonce: %d\ndata: %s\nhashHex: %s\nelapsed: %s\n", nonce, data, hashHex, elapsed)
	nonce, data, hashHex, elapsed = findHashWithPrefix(nickname, "00000")
	fmt.Printf("5 zero\n:\nnonce: %d\ndata: %s\nhashHex: %s\nelapsed: %s", nonce, data, hashHex, elapsed)
}

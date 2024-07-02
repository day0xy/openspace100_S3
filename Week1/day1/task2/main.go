// Package main-----------------------------
// @file      : main.go
// @author    : day0xy
// @time      : 7/2/24
// -------------------------------------------
package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"os"
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

func GenKeyPair(bits int, privateKeyPath, PublicKeyPath string) error {
	//生成私钥
	privateKey, err := rsa.GenerateKey(rand.Reader, bits)
	if err != nil {
		return err
	}
	derPrivateStream := x509.MarshalPKCS1PrivateKey(privateKey)
	block := pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: derPrivateStream,
	}
	privateFile, err := os.Create(privateKeyPath)
	defer privateFile.Close()
	if err != nil {
		return err
	}
	err = pem.Encode(privateFile, &block)
	if err != nil {
		return err
	}

	//生成公钥
	publicKey := privateKey.PublicKey
	derPublicStream, err := x509.MarshalPKIXPublicKey(&publicKey)
	if err != nil {
		return err
	}
	block = pem.Block{
		Type:  "RSA PUBLIC KEY",
		Bytes: derPublicStream,
	}

	publicFile, err := os.Create(PublicKeyPath)
	defer publicFile.Close()

	if err != nil {
		return err
	}

	//  编码公钥, 写入文件
	err = pem.Encode(publicFile, &block)
	if err != nil {
		panic(err)
		return err
	}
	return nil

}

func RSAEncrypt(src []byte, filename string) ([]byte, error) {
	// 根据文件名读出文件内容
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	info, _ := file.Stat()
	buf := make([]byte, info.Size())
	file.Read(buf)

	// 从数据中找出pem格式的块
	block, _ := pem.Decode(buf)
	if block == nil {
		return nil, err
	}

	// 解析一个der编码的公钥
	publicKey, err := x509.ParsePKCS1PublicKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	// 公钥加密
	result, _ := rsa.EncryptPKCS1v15(rand.Reader, publicKey, src)
	return result, nil

}

func RSADecrypt(src []byte, filename string) ([]byte, error) {
	// 根据文件名读出内容
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	info, _ := file.Stat()
	buf := make([]byte, info.Size())
	file.Read(buf)

	// 从数据中解析出pem块
	block, _ := pem.Decode(buf)
	if block == nil {
		return nil, err
	}

	// 解析出一个der编码的私钥
	privateKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)

	// 私钥解密
	result, err := rsa.DecryptPKCS1v15(rand.Reader, privateKey, src)
	if err != nil {
		return nil, err
	}
	return result, nil
}

// 函数：检查文件是否存在
func fileExists(filename string) bool {
	_, err := os.Stat(filename)
	return !os.IsNotExist(err)
}

func main() {
	nickname := "day0xy"
	filename1 := "privateKey.pem"
	filename2 := "publicKey.pem"
	nonce, _, _ := findHashWithPrefix(nickname, "0000")
	encryptData := fmt.Sprintf("%s%d", nickname, nonce)
	fmt.Println(encryptData)

	if fileExists(filename1) && fileExists(filename2) {
		GenKeyPair(2048, "privateKey.pem", "publicKey.pem")
	}

	cipherText, _ := RSAEncrypt([]byte(encryptData), "./publicKey.pem")
	fmt.Println(string(cipherText))
	plainText, _ := RSADecrypt(cipherText, "./privateKey.pem")
	fmt.Println(string(plainText))

}

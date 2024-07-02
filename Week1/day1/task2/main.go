// Package main-----------------------------
// @file      : main.go
// @author    : day0xy
// @time      : 7/2/24
// -------------------------------------------
package main

import (
	"crypto"
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

	// 无限循环找nonce
	for {
		data := fmt.Sprintf("%s%d", nickname, nonce)
		hash := sha256.Sum256([]byte(data))
		hashHex := fmt.Sprintf("%x", hash)

		if strings.HasPrefix(hashHex, prefix) {
			return nonce, data, hashHex
		}
		nonce++
	}
}

func GenKeyPair(bits int, privateKeyPath, publicKeyPath string) error {
	// 生成私钥
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
	if err != nil {
		return err
	}
	defer privateFile.Close()

	err = pem.Encode(privateFile, &block)
	if err != nil {
		return err
	}

	// 生成公钥
	publicKey := privateKey.PublicKey
	derPublicStream, err := x509.MarshalPKIXPublicKey(&publicKey)
	if err != nil {
		return err
	}
	block = pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: derPublicStream,
	}

	publicFile, err := os.Create(publicKeyPath)
	if err != nil {
		return err
	}
	defer publicFile.Close()

	// 编码公钥, 写入文件
	err = pem.Encode(publicFile, &block)
	if err != nil {
		return err
	}
	return nil
}

func SignWithPrivateKey(data []byte, privateKeyPath string) ([]byte, error) {
	// 根据文件名读出私钥
	file, err := os.Open(privateKeyPath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	info, _ := file.Stat()
	buf := make([]byte, info.Size())
	_, err = file.Read(buf)
	if err != nil {
		return nil, err
	}

	// 从数据中解析出pem块
	block, _ := pem.Decode(buf)
	if block == nil {
		return nil, fmt.Errorf("failed to decode PEM block")
	}

	// 解析出一个der编码的私钥
	privateKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	// 生成哈希
	hashed := sha256.Sum256(data)

	// 私钥签名
	signature, err := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA256, hashed[:])
	if err != nil {
		return nil, err
	}
	return signature, nil
}

func VerifyWithPublicKey(data []byte, signature []byte, publicKeyPath string) error {
	// 根据文件名读出公钥
	file, err := os.Open(publicKeyPath)
	if err != nil {
		return err
	}
	defer file.Close()

	info, _ := file.Stat()
	buf := make([]byte, info.Size())
	_, err = file.Read(buf)
	if err != nil {
		return err
	}

	// 从数据中找出pem格式的块
	block, _ := pem.Decode(buf)
	if block == nil {
		return fmt.Errorf("failed to decode PEM block")
	}

	// 解析一个der编码的公钥
	pubInterface, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return err
	}
	publicKey, ok := pubInterface.(*rsa.PublicKey)
	if !ok {
		return fmt.Errorf("not RSA public key")
	}

	// 生成哈希
	hashed := sha256.Sum256(data)

	// 公钥验证签名
	err = rsa.VerifyPKCS1v15(publicKey, crypto.SHA256, hashed[:], signature)
	if err != nil {
		return err
	}
	return nil
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
	signData := fmt.Sprintf("%s%d", nickname, nonce)
	fmt.Println("Data to sign:", signData)

	if !fileExists(filename1) || !fileExists(filename2) {
		err := GenKeyPair(2048, filename1, filename2)
		if err != nil {
			fmt.Println("Error generating key pair:", err)
			return
		}
	}

	// 用私钥签名
	signature, err := SignWithPrivateKey([]byte(signData), filename1)
	if err != nil {
		fmt.Println("Error signing data:", err)
		return
	}
	fmt.Println("Signature:", signature)

	// 用公钥验证签名
	err = VerifyWithPublicKey([]byte(signData), signature, filename2)
	if err != nil {
		fmt.Println("Signature verification failed:", err)
		return
	}
	fmt.Println("Signature verification successful")
}

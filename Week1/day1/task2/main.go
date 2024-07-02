// Package main-----------------------------
// @file      : main.go
// @author    : day0xy
// @time      : 7/2/24
// -------------------------------------------
package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"os"
)

func GenKeyPair(bits int, privateKeyPath, PublicKeyPath string) error {
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

}

#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'

rm -r ca

# Prepare the directory
echo -e "${RED}ROOT${NC} Prepare the directory"
mkdir ca
mkdir ca/certs ca/crl ca/newcerts ca/private
chmod 700 ca/private
touch ca/index.txt
echo 1000 > ca/serial

# Prepare the configuration file
echo -e "${RED}ROOT${NC} Prepare the configuration file"
cp root_openssl.cnf ca/openssl.cnf

# Create the root key
echo -e "${RED}ROOT${NC} Create the root key"
openssl genrsa -aes256 -out ca/private/ca.key.pem 4096
chmod 400 ca/private/ca.key.pem

# Create the root certificate
echo -e "${RED}ROOT${NC} Create the root certificate"
openssl req -config ca/openssl.cnf \
      -key ca/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out ca/certs/ca.cert.pem
chmod 444 ca/certs/ca.cert.pem

# Verify the root certificate
echo -e "${RED}ROOT${NC} Verify the root certificate"
openssl x509 -noout -text -in ca/certs/ca.cert.pem


# INTERMEDIATE
# Prepare the directory
echo -e "${RED}INTERMEDIATE${NC} Prepare the directory"
mkdir ca/intermediate

mkdir ca/intermediate/certs 
mkdir ca/intermediate/crl
mkdir ca/intermediate/csr
mkdir ca/intermediate/newcerts
mkdir ca/intermediate/private

chmod 700 ca/intermediate/private
touch ca/intermediate/index.txt
echo 1000 > ca/intermediate/serial
echo 1000 > ca/intermediate/crlnumber

# Prepare the configuration file
echo -e "${RED}INTERMEDIATE${NC} Prepare the configuration file"
cp intermediate_openssl.cnf ca/intermediate/openssl.cnf

# Create the intermediate key
echo -e "${RED}INTERMEDIATE${NC} Create the intermediate key"
openssl genrsa -aes256 \
      -out ca/intermediate/private/intermediate.key.pem 4096
chmod 400 ca/intermediate/private/intermediate.key.pem

# Create the intermediate certificate
echo -e "${RED}INTERMEDIATE${NC} Create the intermediate certificate"
echo -e "${RED}INTERMEDIATE${NC} openssl req"
openssl req -config ca/intermediate/openssl.cnf -new -sha256 \
      -key ca/intermediate/private/intermediate.key.pem \
      -out ca/intermediate/csr/intermediate.csr.pem

echo -e "${RED}INTERMEDIATE${NC} openssl ca"
openssl ca -config ca/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in ca/intermediate/csr/intermediate.csr.pem \
      -out ca/intermediate/certs/intermediate.cert.pem
chmod 444 ca/intermediate/certs/intermediate.cert.pem

# Verify the intermediate certificate
echo -e "${RED}INTERMEDIATE${NC} Verify the intermediate certificate"
openssl x509 -noout -text \
      -in ca/intermediate/certs/intermediate.cert.pem

echo -e "${RED}INTERMEDIATE${NC} openssl verify intermediate with ca root"
openssl verify -CAfile ca/certs/ca.cert.pem \
      ca/intermediate/certs/intermediate.cert.pem

# Create the certificate chain file
echo -e "${RED}INTERMEDIATE${NC} Create the certificate chain file"
cat ca/intermediate/certs/intermediate.cert.pem \
    ca/certs/ca.cert.pem > ca/intermediate/certs/ca-chain.cert.pem
chmod 444 ca/intermediate/certs/ca-chain.cert.pem

# SERVER

# Create a key
echo -e "${RED}SERVER${NC} Create a key"
openssl genrsa -aes256 \
      -out ca/intermediate/private/www.example.com.key.pem 2048
chmod 400 ca/intermediate/private/www.example.com.key.pem

# Create a certificate
echo -e "${RED}SERVER${NC} Create a certificate"
echo -e "${RED}SERVER${NC} openssl req"
openssl req -config ca/intermediate/openssl.cnf \
      -key ca/intermediate/private/www.example.com.key.pem \
      -new -sha256 -out ca/intermediate/csr/www.example.com.csr.pem


echo -e "${RED}SERVER${NC} openssl ca"
openssl ca -config ca/intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in ca/intermediate/csr/www.example.com.csr.pem \
      -out ca/intermediate/certs/www.example.com.cert.pem
chmod 444 ca/intermediate/certs/www.example.com.cert.pem

# Verify the certificate
echo -e "${RED}SERVER${NC} Verify the certificate"
openssl x509 -noout -text \
      -in ca/intermediate/certs/www.example.com.cert.pem

echo -e "${RED}SERVER${NC} openssl verify server with ca chain"
openssl verify -CAfile ca/intermediate/certs/ca-chain.cert.pem \
      ca/intermediate/certs/www.example.com.cert.pem

echo -e "${RED}SERVER${NC} END"

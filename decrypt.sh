#!/bin/bash

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <filename> <decryption_key>"
    exit 1
fi

# Get the filename and decryption key from the arguments
ENCRYPTED_FILE="$1"
DECRYPTION_KEY="$2"

# Decrypt the file using AES
openssl aes-256-cbc -d -pbkdf2 -in "$ENCRYPTED_FILE" -out "backup_decrypted.sql" -pass pass:"$DECRYPTION_KEY"

echo "Decryption completed. Decrypted file: backup_decrypted.sql"

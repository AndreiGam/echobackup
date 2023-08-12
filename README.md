# EchoBackup

This bash script performs backup and transfer of a MariaDB database using FTP. It prompts the user for configuration values if they are missing and saves them to a configuration file for future use.

## Features
- Prompt user for configuration values if they are missing.
- Load configuration values from a file if it exists.
- Save configuration values to a file if they don't exist already.
- Perform a database backup using `mariadb-dump`.
- Encrypt the backup file using AES-256.
- Transfer the encrypted backup file to a remote server using FTP.
- Delete old backup directories that are older than 7 days.
- Decrypts a file using AES encryption algorithm

## Requirements
- MariaDB command-line tools (`mariadb-dump`)
- OpenSSL (`openssl`)
- LFTP (`lftp`)

## Installation

1. Make sure all the required tools are installed on your system.
2. Download the `backup.sh` script to a desired directory.

## Usage

1. Open a terminal and navigate to the directory where the `backup.sh` script is located.
2. Run the script with the following command:

```shell
./backup.sh
```
The script will prompt you for configuration values if they are missing and save them to a configuration file (`config`) for future use.

## Decrypt Usage
```
./decrypt.sh <filename> <decryption_key>
```

- `<filename>`: The name of the encrypted file that needs to be decrypted.
- `<decryption_key>`: The key used for decryption.


## License
This script is released under the [MIT License](https://opensource.org/licenses/MIT).


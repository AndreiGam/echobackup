#!/bin/bash

CONFIG_FILE="config"
BACKUP_FILE="backup.sql"

# Function to read user input
read_config_value() {
    read -p "Enter $1: " value
    echo "$value"
}

# Function to check if config file exists and load the values
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "Config file loaded."
    fi
}

# Function to check if config value exists in the file
config_value_exists() {
    grep -q "^$1=" "$CONFIG_FILE"
}

# Function to save config values to the file
save_config() {
    declare -A config_values=(
        ["db_host"]="$db_host"
        ["db_port"]="$db_port"
        ["db_user"]="$db_user"
        ["db_pass"]="$db_pass"
        ["db_name"]="$db_name"
        ["encryption_key"]="$encryption_key"
        ["ftp_host"]="$ftp_host"
        ["ftp_username"]="$ftp_username"
        ["ftp_password"]="$ftp_password"
        ["app_name"]="$app_name"
    )

    for key in "${!config_values[@]}"; do
        if ! config_value_exists "$key"; then
            echo "$key=${config_values[$key]}" >> "$CONFIG_FILE"
        fi
    done
}

# Check and load existing config
load_config

# Define the required config keys
required_config=("db_host" "db_port" "db_user" "db_pass" "app_name" "encryption_key" "ftp_host" "ftp_username" "ftp_password")

# Loop to prompt for missing values
for config_key in "${required_config[@]}"; do
    if [[ -z "${!config_key}" ]]; then
        declare "$config_key"=$(read_config_value "$config_key")
    fi
done

# Save the config to the file if it doesn't exist already
if [ ! -f "$CONFIG_FILE" ]; then
    save_config
fi

# Export DB password as an environment variable (only for this command)
export MYSQL_PWD="$db_pass"

# Execute mariadb-dump
mariadb_dump_command="mariadb-dump --host=$db_host --port=$db_port --user=$db_user --databases $db_name > $BACKUP_FILE"
echo "Executing mariadb-dump..."
echo "Command: $mariadb_dump_command"
eval "$mariadb_dump_command"

# Remove the exported password from the environment after use
unset MYSQL_PWD

# Get the current date as dd-mm-yyyy-hh:mm
current_date=$(date +"%d-%m-%Y-%H:%M")

# Rename the encrypted file with the current date and database name
ENCRYPTED_FILE="${current_date}-${db_name}.backup"

# Encrypt backup file with AES using -pbkdf2 for key derivation
openssl aes-256-cbc -pbkdf2 -salt -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE" -pass pass:"$encryption_key"

# Remove the original backup.sql file
rm "$BACKUP_FILE"

# Transfer the encrypted file to the remote server using FTP
FTP_HOST="$ftp_host"
FTP_USER="$ftp_username"
FTP_PASS="$ftp_password"

current_date_dir=$(date +"%d-%m-%Y")

# Connect to the FTP server with lftp
lftp -u $FTP_USER,$FTP_PASS $FTP_HOST << EOF
# Create the app_name directory if it doesn't exist (suppresses error if it does)
mkdir -f ${app_name^}
# Change to the app_name directory
cd ${app_name^}
# Create the date directory if it doesn't exist (suppresses error if it does)
mkdir -f $current_date_dir
# Change to the date directory
cd $current_date_dir
# Upload the encrypted file
put $ENCRYPTED_FILE
# Exit lftp
quit
EOF

rm $ENCRYPTED_FILE

# Connect to the FTP server with lftp and list the directories
directories=$(lftp -u $FTP_USER,$FTP_PASS $FTP_HOST << EOF
cd ${app_name^}
ls
quit
EOF
)

# Get the current date in seconds since the epoch
current_date_seconds=$(date +%s)

# Loop through the directory names
while read -r line; do
  # Extract the directory name
  dir_name=$(echo $line | awk '{print $NF}')
  # Extract the day, month, and year components
  IFS="-" read -ra date_parts <<< "$dir_name"
  day="${date_parts[0]}"
  month="${date_parts[1]}"
  year="${date_parts[2]}"
  # Convert the directory date to seconds since the epoch
  dir_date=$(date --date="$year-$month-$day" +%s || echo 0)
  # Calculate the age of the directory in days
  age=$(( (current_date_seconds - dir_date) / 86400 ))
  # If the directory is older than 7 days, delete it
  if [ $age -gt 7 ]; then
    lftp -u $FTP_USER,$FTP_PASS $FTP_HOST << EOF
    cd ${app_name^}
    cd $dir_name
    # Delete all files in the directory
    mrm *
    # Go back to the parent directory
    cd ..
    # Delete the directory itself
    rmdir $dir_name
    quit
EOF
  fi
done <<< "$directories"







#!/bin/bash

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Check if the input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input-file>"
    exit 1
fi

INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure the password file directory exists
mkdir -p /var/secure

# Ensure the log file exists
touch $LOG_FILE
chmod 644 $LOG_FILE

# Ensure the password file exists
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Trim whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    if id "$username" &>/dev/null; then
        echo "User $username already exists." | tee -a $LOG_FILE
        continue
    fi

    # Create the user's primary group
    groupadd "$username"
    if [ $? -eq 0 ]; then
        echo "Group $username created." | tee -a $LOG_FILE
    else
        echo "Failed to create group $username." | tee -a $LOG_FILE
        continue
    fi

    # Create user with home directory and personal group
    useradd -m -g "$username" "$username"
    if [ $? -eq 0 ]; then
        echo "User $username created." | tee -a $LOG_FILE
    else
        echo "Failed to create user $username." | tee -a $LOG_FILE
        continue
    fi

    # Add user to additional groups if specified
    if [ -n "$groups" ]; then
        IFS=',' read -ra ADDR <<< "$groups"
        for group in "${ADDR[@]}"; do
            group=$(echo "$group" | xargs)
            if getent group "$group" &>/dev/null; then
                usermod -aG "$group" "$username"
                echo "User $username added to group $group." | tee -a $LOG_FILE
            else
                groupadd "$group"
                usermod -aG "$group" "$username"
                echo "Group $group created and user $username added to it." | tee -a $LOG_FILE
            fi
        done
    fi

    # Set home directory permissions
    chmod 700 "/home/$username"
    chown "$username:$username" "/home/$username"
    echo "Home directory for $username set up." | tee -a $LOG_FILE

    # Generate random password
    password=$(generate_password)
    echo "$username,$password" >> $PASSWORD_FILE
    echo "Password for $username generated and stored." | tee -a $LOG_FILE

    # Set the password for the user
    echo "$username:$password" | chpasswd
    echo "Password for $username set." | tee -a $LOG_FILE

done < "$INPUT_FILE"

echo "User creation process completed." | tee -a $LOG_FILE

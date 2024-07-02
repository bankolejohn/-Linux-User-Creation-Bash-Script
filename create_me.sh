#!/bin/bash

# Script location for logging
SCRIPT_DIR=$(realpath "$0")
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Check for required argument (user data file)
if [ $# -eq 0 ]; then
  echo "Error: Please provide a text file containing user data." >&2
  exit 1
fi

# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
  echo "Error: This script requires root privileges." >&2
  exit 1
fi

# Open log file in append mode
exec &>> "$LOG_FILE"

# Function to create user and group
create_user_and_group() {
  username="$1"
  groups="$2"

  # Create user group
  groupadd "$username" 2>> "$LOG_FILE"

  # Check if user already exists
  if id -u "$username" >/dev/null 2>&1; then
    echo "WARNING: User '$username' already exists, skipping..."
  else
    # Create user with home directory
    useradd -m -g "$username" -s /bin/bash "$username" 2>> "$LOG_FILE"

    # Generate random password
    password=$(< /dev/urandom tr -dc A-Za-z0-9!@#$%^&*() | head -c16 ; echo)

    # Set user password
    echo "$username:$password" | chpasswd --stdin 2>> "$LOG_FILE"

    # Log user creation
    echo "Created user '$username' with password '$password'"

    # Store username and password
    echo "$username,$password" >> "$PASSWORD_FILE"

    # Set group memberships (excluding personal group)
    for group in $(echo "$groups" | tr ',' ' '); do
      if [ "$group" != "$username" ]; then
        usermod -aG "$group" "$username" 2>> "$LOG_FILE"
      fi
    done
  fi
}

# Process each line in the user data file
while IFS=';' read -r username groups; do
  create_user_and_group "$username" "$groups"
done < "$1"

# Close log file
exec >&2

# Set secure permissions on password file
chmod 600 "$PASSWORD_FILE"

echo "User creation completed. See log file '$LOG_FILE' for details."

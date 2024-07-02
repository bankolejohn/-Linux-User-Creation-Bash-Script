#!/bin/bash

# Log file
LOG_FILE="/var/log/user_management.log"
# Secure password file
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the log file and password file exist
touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to generate a random password
generate_password() {
	    local password_length=12
	        echo $(tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length)
	}

# Function to log messages
log_message() {
	    local message="$1"
	        echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a $LOG_FILE
	}

# Ensure the script is run with a file argument
if [ $# -eq 0 ]; then
	    log_message "No input file provided."
	        exit 1
fi

# Read the file line by line
while IFS=';' read -r username groups; do
	    # Ignore whitespace
	        username=$(echo $username | xargs)
		    groups=$(echo $groups | xargs)

		        # Skip empty lines
			    if [ -z "$username" ]; then
				            continue
					        fi

						    # Create the user's primary group
						        if ! getent group "$username" > /dev/null 2>&1; then
								        groupadd "$username"
									        log_message "Group '$username' created."
										    else
											            log_message "Group '$username' already exists."
												        fi

													    # Create the user if it doesn't exist
													        if ! id "$username" > /dev/null 2>&1; then
															        useradd -m -g "$username" -s /bin/bash "$username"
																        log_message "User '$username' created."
																	    else
																		            log_message "User '$username' already exists."
																			        fi

																				    # Add the user to specified groups
																				        IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)
        if ! getent group "$group" > /dev/null 2>&1; then
            groupadd "$group"
            log_message "Group '$group' created."
        fi
        usermod -aG "$group" "$username"
        log_message "User '$username' added to group '$group'."
    done

    # Set the user's home directory permissions
    chmod 700 "/home/$username"
    chown "$username:$username" "/home/$username"
    log_message "Set permissions for home directory of '$username'."

    # Generate and store the user's password
    password=$(generate_password)
    echo "$username,$password" >> $PASSWORD_FILE
    echo "$username:$password" | chpasswd
    log_message "Password set for user '$username'."

done < "$1"

log_message "User creation process completed."


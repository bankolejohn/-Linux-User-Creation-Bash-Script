# #!/bin/bash

# # Log file
# LOG_FILE="/var/log/user_management.log"
# # Secure password file
# PASSWORD_FILE="/var/secure/user_passwords.csv"

# # Ensure the log file and password file exist
# touch $LOG_FILE
# touch $PASSWORD_FILE
# chmod 600 $PASSWORD_FILE

# # Function to generate a random password
# generate_password() {
# 	    local password_length=12
# 	        echo $(tr -dc A-Za-z0-9 </dev/urandom | head -c $password_length)
# 	}

# # Function to log messages
# log_message() {
# 	    local message="$1"
# 	        echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a $LOG_FILE
# 	}

# # Ensure the script is run with a file argument
# if [ $# -eq 0 ]; then
# 	    log_message "No input file provided."
# 	        exit 1
# fi

# # Read the file line by line
# while IFS=';' read -r username groups; do
# 	    # Ignore whitespace
# 	        username=$(echo $username | xargs)
# 		    groups=$(echo $groups | xargs)

# 		        # Skip empty lines
# 			    if [ -z "$username" ]; then
# 				            continue
# 					        fi

# 						    # Create the user's primary group
# 						        if ! getent group "$username" > /dev/null 2>&1; then
# 								        groupadd "$username"
# 									        log_message "Group '$username' created."
# 										    else
# 											            log_message "Group '$username' already exists."
# 												        fi

# 													    # Create the user if it doesn't exist
# 													        if ! id "$username" > /dev/null 2>&1; then
# 															        useradd -m -g "$username" -s /bin/bash "$username"
# 																        log_message "User '$username' created."
# 																	    else
# 																		            log_message "User '$username' already exists."
# 																			        fi

# 																				    # Add the user to specified groups
# 																				        IFS=',' read -r -a group_array <<< "$groups"
#     for group in "${group_array[@]}"; do
#         group=$(echo $group | xargs)
#         if ! getent group "$group" > /dev/null 2>&1; then
#             groupadd "$group"
#             log_message "Group '$group' created."
#         fi
#         usermod -aG "$group" "$username"
#         log_message "User '$username' added to group '$group'."
#     done

#     # Set the user's home directory permissions
#     chmod 700 "/home/$username"
#     chown "$username:$username" "/home/$username"
#     log_message "Set permissions for home directory of '$username'."

#     # Generate and store the user's password
#     password=$(generate_password)
#     echo "$username,$password" >> $PASSWORD_FILE
#     echo "$username:$password" | chpasswd
#     log_message "Password set for user '$username'."

# done < "$1"

# log_message "User creation process completed."





# #!/bin/bash

# # Log file path
# LOG_FILE="/var/log/user_management.log"

# # Password file path
# PASSWORD_FILE="/var/secure/user_passwords.txt"

# # Input file containing user and group information
# INPUT_FILE="$1"

# # Function to log messages without timestamps
# log_message() {
#     local message="$1"
#     echo "$message" | tee -a $LOG_FILE
# }

# # Function to generate a random password
# generate_password() {
#     openssl rand -base64 12
# }

# # Ensure the log and password files exist with proper permissions
# touch $LOG_FILE
# chmod 644 $LOG_FILE
# mkdir -p $(dirname $PASSWORD_FILE)
# touch $PASSWORD_FILE
# chmod 600 $PASSWORD_FILE

# # Check if the input file is provided
# if [ -z "$INPUT_FILE" ]; then
#     log_message "Error: No input file provided."
#     exit 1
# fi

# # Read the input file and process each line
# while IFS=";" read -r username groups; do
#     # Trim whitespace
#     username=$(echo $username | xargs)
#     groups=$(echo $groups | xargs)

#     # Create user and personal group
#     if id "$username" &>/dev/null; then
#         log_message "User $username already exists."
#     else
#         # Create the user with a home directory and default shell
#         useradd -m -s /bin/bash "$username"
#         log_message "User $username created successfully."

#         # Generate and set a random password
#         password=$(generate_password)
#         echo "$username:$password" | chpasswd
#         echo "$username,$password" >> $PASSWORD_FILE
#         log_message "Password set for user $username."

#         # Create a personal group with the same name as the user
#         usermod -aG "$username" "$username"
#         log_message "Personal group $username created for user $username."

#         # Add user to additional groups
#         IFS=',' read -r -a group_array <<< "$groups"
#         for group in "${group_array[@]}"; do
#             group=$(echo $group | xargs) # Trim whitespace
#             if getent group "$group" &>/dev/null; then
#                 usermod -aG "$group" "$username"
#                 log_message "Added user $username to group $group."
#             else
#                 groupadd "$group"
#                 usermod -aG "$group" "$username"
#                 log_message "Group $group created and user $username added to it."
#             fi
#         done
#     fi
# done < "$INPUT_FILE"

# log_message "User creation process completed."




#!/bin/bash

# Log file and secure password file
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure the secure directory exists and set appropriate permissions
mkdir -p /var/secure
chmod 700 /var/secure

# Ensure the log file exists and set appropriate permissions
touch $LOG_FILE
chmod 644 $LOG_FILE

# Check if the script is run with a file argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <user_file>" | tee -a $LOG_FILE
    exit 1
fi

USER_FILE=$1

# Check if the user file exists
if [ ! -f $USER_FILE ]; then
    echo "User file not found: $USER_FILE" | tee -a $LOG_FILE
    exit 1
fi

# Function to generate random password
generate_password() {
    local PASSWORD_LENGTH=12
    tr -dc A-Za-z0-9 </dev/urandom | head -c $PASSWORD_LENGTH
}

# Read the user file and process each line
while IFS=';' read -r USERNAME GROUPS; do
    # Trim whitespace
    USERNAME=$(echo $USERNAME | xargs)
    GROUPS=$(echo $GROUPS | xargs)
    
    # Skip empty lines
    if [ -z "$USERNAME" ]; then
        continue
    fi

    # Create the user and primary group
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists" | tee -a $LOG_FILE
    else
        useradd -m -s /bin/bash $USERNAME
        echo "User $USERNAME created" | tee -a $LOG_FILE
    fi

    # Create user's personal group
    if getent group "$USERNAME" &>/dev/null; then
        echo "Group $USERNAME already exists" | tee -a $LOG_FILE
    else
        groupadd $USERNAME
        usermod -g $USERNAME $USERNAME
        echo "Group $USERNAME created and assigned to $USERNAME" | tee -a $LOG_FILE
    fi

    # Add user to additional groups
    if [ -n "$GROUPS" ]; then
        IFS=',' read -ra ADDITIONAL_GROUPS <<< "$GROUPS"
        for GROUP in "${ADDITIONAL_GROUPS[@]}"; do
            GROUP=$(echo $GROUP | xargs)
            if getent group "$GROUP" &>/dev/null; then
                usermod -aG $GROUP $USERNAME
                echo "User $USERNAME added to group $GROUP" | tee -a $LOG_FILE
            else
                groupadd $GROUP
                usermod -aG $GROUP $USERNAME
                echo "Group $GROUP created and user $USERNAME added to it" | tee -a $LOG_FILE
            fi
        done
    fi

    # Generate random password
    PASSWORD=$(generate_password)
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "$USERNAME,$PASSWORD" >> $PASSWORD_FILE
    chmod 600 $PASSWORD_FILE
    echo "Password for $USERNAME set and stored securely" | tee -a $LOG_FILE

done < "$USER_FILE"

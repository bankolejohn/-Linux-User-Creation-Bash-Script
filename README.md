# Technical Article
## Automating User Creation in Linux with a Bash Script
As a SysOps engineer, managing users and groups efficiently is crucial, especially when onboarding new developers. Automating this process ensures consistency and saves time. Here, I will walk you through a Bash script, create_users.sh, designed to create users and groups, set up home directories, generate random passwords, and log all actions.

### Script Overview
The script reads a text file containing usernames and groups, creates users and groups, sets up home directories, generates random passwords, and logs actions to /var/log/user_management.log. Passwords are securely stored in /var/secure/user_passwords.txt.

### Prerequisites
Ensure you have root or sudo privileges as the script requires administrative access to create users and groups.

### Script Breakdown


#### Generate Random Password:
Generating a random password using OpenSSL ensures that each user gets a secure, unpredictable password.

```
generate_password() {
    openssl rand -base64 12
}
```

#### Check Input File:

```
if [ -z "$1" ]; then
    echo "Usage: $0 <input-file>"
    exit 1
fi
```
This checks if the user has provided the required input file. If not, it provides a usage message and exits the script. This ensures the script is used correctly.

#### Set Up Logging and Secure Password Storage:

```
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"
mkdir -p /var/secure
touch $LOG_FILE
chmod 644 $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE
```
Setting up a log file allows tracking of actions, which is crucial for troubleshooting and auditing. Storing passwords securely with restricted permissions ensures that only authorized users can access them, enhancing security.



#### Read and Process Input File:


```
while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)
```
Reading the input file line by line and trimming whitespace ensures that each user and their groups are handled correctly, preventing issues with extra spaces.

#### Create User and Personal Group:

```
if id "$username" &>/dev/null; then
    echo "User $username already exists." | tee -a $LOG_FILE
    continue
fi
useradd -m -g "$username" "$username"
```
Checking if the user exists prevents errors from trying to recreate existing users. Creating a personal group for each user is a common practice to isolate permissions, and then creating the user with that group ensures proper setup.

#### Assign Additional Groups:

```
if [ -n "$groups" ]; then
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
        group=$(echo "$group" | xargs)
        if getent group "$group" &>/dev/null; then
            usermod -aG "$group" "$username"
            echo "User $username added to group $group." | tee -a $LOG_FILE
        else
            echo "Group $group does not exist. Skipping for user $username." | tee -a $LOG_FILE
        fi
    done
fi
```
Adding users to multiple groups allows for flexible permission management, enabling users to have access to different resources as needed. Creating missing groups on the fly ensures smooth execution without manual intervention.

#### Set Home Directory Permissions:

Setting strict permissions ensures that only the user can access their home directory, enhancing security and privacy. Changing ownership ensures that the user has full control over their own files.

```chmod 700 "/home/$username"
chown "$username:$username" "/home/$username"
```


#### Generate and Set Password:

```password=$(generate_password)
echo "$username,$password" >> $PASSWORD_FILE
echo "$username:$password" | chpasswd
```
Storing passwords securely and setting them for users automates the process, ensuring each user has a unique, strong password. This is crucial for maintaining security standards.

#### Logging and Completion:

```echo "User creation process completed." | tee -a $LOG_FILE```
Logging the completion of the process provides a clear end point for auditing purposes and ensures that administrators are aware of the script's progress and any issues that may have occurred.

##### script running successfully on AWS ubuntu 22.04
![task_1](https://github.com/bankolejohn/-Linux-User-Creation-Bash-Script/assets/76499525/fd7bc86d-cfa9-4f6c-b244-bc90136c9d6c)



### Conclusion
Automating user creation in Linux with a Bash script streamlines the onboarding process, ensuring efficiency and security. By following the steps outlined above, you can easily manage user accounts and groups in a consistent manner.

For more information about the HNG Internship and opportunities to enhance your skills, visit the HNG Internship website [https://hng.tech/internship] and learn how you can hire top talents from the program [ https://hng.tech/hire]

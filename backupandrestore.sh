#!/bin/bash

# Function to display the banner
display_banner() {
    echo "########################################"
    echo "#                                      #"
    echo "#          Welcome to Backup           #"
    echo "#               System                 #"
    echo "#                                      #"
    echo "########################################"
}

# Function to display the menu
display_menu() {
    echo "================================"
    echo "         Backup System          "
    echo "================================"
    echo "1) What do you want to backup?"
    echo "2) Where do you want to backup?"
    echo "3) Restore from backup"
    echo "4) Exit"
    echo "================================"
    read -p "Choose an option: " option
}

# Function to set up SSH key authentication
setup_ssh_key() {
    local remote_ip=$1
    local user=$2

    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo "Generating SSH keys..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
    fi

    echo "Copying SSH key to remote server..."
    ssh-copy-id -i "$HOME/.ssh/id_rsa.pub" -o "Port=$remote_port" "$user@$remote_ip"
    if [ $? -eq 0 ]; then
        echo "SSH key setup successful."
    else
        echo "Failed to set up SSH key. Ensure SSH access is allowed and credentials are correct."
        exit 1
    fi
}

# Main script
display_banner
while true; do
    display_menu
    case $option in
        1)
            read -p "Enter the path of the directory you want to backup: " backup_source
            if [ ! -d "$backup_source" ]; then
                echo "Invalid directory. Please try again."
            else
                echo "Backup source set to: $backup_source"
            fi
            ;;
        2)
            echo "Select backup destination:"
            echo "1) Local"
            echo "2) Remote"
            read -p "Choose an option: " destination_option
            case $destination_option in
                1)
                    read -p "Enter the local backup path: " local_backup_path
                    mkdir -p "$local_backup_path"
                    echo "Starting local backup..."
                    rsync -av --progress "$backup_source" "$local_backup_path"
                    if [ $? -eq 0 ]; then
                        echo "Local backup completed successfully."
                    else
                        echo "Local backup failed."
                    fi
                    ;;
                2)
                    read -p "Enter the remote server IP address: " remote_ip
                    read -p "Enter the remote server username: " remote_user
                    read -p "Enter the remote server SSH port: " remote_port
                    read -p "Enter the remote backup path: " remote_backup_path

                    echo "Setting up SSH key authentication..."
                    setup_ssh_key "$remote_ip" "$remote_user"

                    echo "Starting remote backup..."
                    rsync -av --progress -e "ssh -p $remote_port" "$backup_source" "$remote_user@$remote_ip:$remote_backup_path"
                    if [ $? -eq 0 ]; then
                        echo "Remote backup completed successfully."
                    else
                        echo "Remote backup failed."
                    fi
                    ;;
                *)
                    echo "Invalid option. Returning to main menu."
                    ;;
            esac
            ;;
        3)
            echo "Select restore source:"
            echo "1) Local"
            echo "2) Remote"
            read -p "Choose an option: " restore_option
            case $restore_option in
                1)
                    read -p "Enter the local backup path: " local_backup_path
                    read -p "Enter the path to restore to: " restore_target
                    echo "Restoring from local backup..."
                    rsync -av --progress "$local_backup_path" "$restore_target"
                    if [ $? -eq 0 ]; then
                        echo "Local restore completed successfully."
                    else
                        echo "Local restore failed."
                    fi
                    ;;
                2)
                    read -p "Enter the remote server IP address: " remote_ip
                    read -p "Enter the remote server username: " remote_user
                    read -p "Enter the remote server SSH port: " remote_port
                    read -p "Enter the remote backup path: " remote_backup_path
                    read -p "Enter the path to restore to: " restore_target

                    echo "Restoring from remote backup..."
                    rsync -av --progress -e "ssh -p $remote_port" "$remote_user@$remote_ip:$remote_backup_path" "$restore_target"
                    if [ $? -eq 0 ]; then
                        echo "Remote restore completed successfully."
                    else
                        echo "Remote restore failed."
                    fi
                    ;;
                *)
                    echo "Invalid option. Returning to main menu."
                    ;;
            esac
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

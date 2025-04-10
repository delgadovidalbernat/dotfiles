#!/bin/bash
# Dotfiles installer script
# Author: Bernat
# Description: Script to symlink all configuration files to their proper locations, 
#              install dependencies, and set up encrypted sensitive data

set -e

# Colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directories
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to create symlinks
create_symlink() {
    local src="$1"
    local dst="$2"
    
    # Check if destination exists
    if [ -e "$dst" ]; then
        printf "${YELLOW}Backing up existing ${dst} to ${BACKUP_DIR}${NC}\n"
        mkdir -p "$(dirname "${BACKUP_DIR}/${dst#$HOME/}")"
        mv "$dst" "${BACKUP_DIR}/${dst#$HOME/}"
    fi
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dst")"
    
    # Create symlink
    ln -sf "$src" "$dst"
    printf "${GREEN}Created symlink: ${dst} -> ${src}${NC}\n"
}

# Function to check if git-crypt is unlocked 
check_git_crypt_unlocked() {
    if [ -f "$DOTFILES_DIR/.ssh/id_rsa" ]; then
        # Try to read the first few bytes of an encrypted file
        if head -c 10 "$DOTFILES_DIR/.ssh/id_rsa" | grep -q "GITCRYPT"; then
            printf "${RED}Repository is locked. Please run 'git-crypt unlock' first.${NC}\n"
            exit 1
        fi
    fi
}

# Function to install packages
install_packages() {
    local packages=("$@")
    printf "${BLUE}Installing packages: ${packages[*]}${NC}\n"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

# Function to create a user
create_user() {
    local username="$1"
    if id "$username" &>/dev/null; then
        printf "${YELLOW}User $username already exists${NC}\n"
    else
        printf "${BLUE}Creating user $username${NC}\n"
        printf "Enter password for new user $username: "
        read -s password
        echo
        printf "Confirm password: "
        read -s password_confirm
        echo
        
        if [ "$password" != "$password_confirm" ]; then
            printf "${RED}Passwords do not match!${NC}\n"
            return 1
        fi
        
        echo "$password" | sudo -S useradd -m -G wheel -s /bin/bash "$username"
        echo "$username:$password" | sudo chpasswd
        printf "${GREEN}User $username created successfully${NC}\n"
    fi
}

# Welcome message
printf "${BLUE}=== Bernat's Dotfiles Installer ===${NC}\n"
printf "This script will install dotfiles for i3, tmux, bash, neovim, ssh and aws configurations.\n"
printf "It will also install required packages and set up a user account.\n"
printf "Existing configurations will be backed up to: ${BACKUP_DIR}\n\n"
printf "${YELLOW}Press enter to continue or Ctrl+C to abort...${NC}\n"
read -r

# Check if git-crypt is unlocked before proceeding
check_git_crypt_unlocked

# Install i3 configuration
printf "${BLUE}=== Installing i3 configuration ===${NC}\n"
create_symlink "$DOTFILES_DIR/i3/config" "$HOME/.config/i3/config"
create_symlink "$DOTFILES_DIR/i3/i3status.conf" "$HOME/.config/i3/i3status.conf"
if [ -d "$DOTFILES_DIR/i3/scripts" ]; then
    for script in "$DOTFILES_DIR"/i3/scripts/*; do
        if [ -f "$script" ]; then
            create_symlink "$script" "$HOME/.config/i3/scripts/$(basename "$script")"
            chmod +x "$HOME/.config/i3/scripts/$(basename "$script")"
        fi
    done
fi

# Install tmux configuration
printf "${BLUE}=== Installing tmux configuration ===${NC}\n"
create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Install bash configuration
printf "${BLUE}=== Installing bash configuration ===${NC}\n"
create_symlink "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
create_symlink "$DOTFILES_DIR/bash/.bash_profile" "$HOME/.bash_profile"
create_symlink "$DOTFILES_DIR/bash/.bash_aliases" "$HOME/.bash_aliases"

# Install Neovim configuration (using external repo)
printf "${BLUE}=== Setting up Neovim configuration ===${NC}\n"
if [ -d "$HOME/.config/nvim" ]; then
    printf "${YELLOW}Backing up existing Neovim configuration to ${BACKUP_DIR}${NC}\n"
    mv "$HOME/.config/nvim" "${BACKUP_DIR}/nvim"
fi
git clone git@github.com:delgadovidalbernat/nvim.git "$HOME/.config/nvim"
printf "${GREEN}Cloned Neovim configuration from external repository${NC}\n"

# Install SSH configuration
printf "${BLUE}=== Installing SSH configuration ===${NC}\n"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -d "$DOTFILES_DIR/.ssh" ]; then
    for file in "$DOTFILES_DIR"/.ssh/*; do
        if [ -f "$file" ]; then
            create_symlink "$file" "$HOME/.ssh/$(basename "$file")"
            # Set appropriate permissions for SSH keys
            if [[ "$(basename "$file")" == id_* && "$(basename "$file")" != "*.pub" ]]; then
                chmod 600 "$HOME/.ssh/$(basename "$file")"
            fi
        fi
    done
fi

# Install AWS configuration
printf "${BLUE}=== Installing AWS configuration ===${NC}\n"
mkdir -p "$HOME/.aws"
if [ -d "$DOTFILES_DIR/.aws" ]; then
    for file in "$DOTFILES_DIR"/.aws/*; do
        if [ -f "$file" ]; then
            create_symlink "$file" "$HOME/.aws/$(basename "$file")"
            # Set appropriate permissions for AWS credentials
            chmod 600 "$HOME/.aws/$(basename "$file")"
        fi
    done
fi

# Install X resources
printf "${BLUE}=== Installing X resources ===${NC}\n"
create_symlink "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources"

# Check for basic package dependencies
printf "${BLUE}=== Checking basic dependencies ===${NC}\n"
DEPENDENCIES=("i3" "tmux" "neovim" "git" "xterm" "git-crypt")
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    printf "${YELLOW}The following dependencies are missing:${NC}\n"
    printf "%s\n" "${MISSING_DEPS[@]}"
    
    printf "Would you like to install them now? (y/n): "
    read -r INSTALL_DEPS
    
    if [[ "$INSTALL_DEPS" == "y" || "$INSTALL_DEPS" == "Y" ]]; then
        printf "${GREEN}Installing dependencies...${NC}\n"
        sudo pacman -S --needed --noconfirm "${MISSING_DEPS[@]}"
    fi
fi

# Install Docker, AWS CLI, and development tools
printf "${BLUE}=== Installing Docker, AWS CLI, and development tools ===${NC}\n"
printf "Do you want to install Docker, AWS CLI, and development tools (Go, Git, GCC, G++, SQL)? (y/n): "
read -r INSTALL_PACKAGES
if [[ "$INSTALL_PACKAGES" == "y" || "$INSTALL_PACKAGES" == "Y" ]]; then
    # Install Docker
    if ! command -v docker &> /dev/null; then
        install_packages docker docker-compose
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker "$USER"
        printf "${GREEN}Docker installed and configured${NC}\n"
    else
        printf "${YELLOW}Docker is already installed${NC}\n"
    fi

    # Install AWS CLI v2
    if ! command -v aws &> /dev/null; then
        printf "${BLUE}Installing AWS CLI v2...${NC}\n"
        install_packages unzip curl
        TEMP_DIR=$(mktemp -d)
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TEMP_DIR/awscliv2.zip"
        unzip -q "$TEMP_DIR/awscliv2.zip" -d "$TEMP_DIR"
        sudo "$TEMP_DIR/aws/install"
        rm -rf "$TEMP_DIR"
        printf "${GREEN}AWS CLI v2 installed${NC}\n"
    else
        printf "${YELLOW}AWS CLI is already installed${NC}\n"
    fi
    
    # Install Go
    if ! command -v go &> /dev/null; then
        printf "${BLUE}Installing Go...${NC}\n"
        install_packages go
        printf "${GREEN}Go installed${NC}\n"
    else
        printf "${YELLOW}Go is already installed${NC}\n"
    fi
    
    # Install Git (should already be installed for git-crypt)
    if ! command -v git &> /dev/null; then
        printf "${BLUE}Installing Git...${NC}\n"
        install_packages git
        printf "${GREEN}Git installed${NC}\n"
    else
        printf "${YELLOW}Git is already installed${NC}\n"
    fi
    
    # Install GCC and G++
    if ! command -v gcc &> /dev/null || ! command -v g++ &> /dev/null; then
        printf "${BLUE}Installing GCC and G++...${NC}\n"
        install_packages gcc g++
        printf "${GREEN}GCC and G++ installed${NC}\n"
    else
        printf "${YELLOW}GCC and G++ are already installed${NC}\n"
    fi
    
    # Install SQL (PostgreSQL)
    if ! command -v psql &> /dev/null; then
        printf "${BLUE}Installing PostgreSQL...${NC}\n"
        install_packages postgresql postgresql-libs
        
        # Initialize the database if not already done
        if [ ! -d "/var/lib/postgres/data" ] || [ -z "$(ls -A /var/lib/postgres/data 2>/dev/null)" ]; then
            printf "${BLUE}Initializing PostgreSQL database...${NC}\n"
            sudo mkdir -p /var/lib/postgres/data
            sudo chown -R postgres:postgres /var/lib/postgres/data
            sudo -u postgres initdb -D /var/lib/postgres/data
        fi
        
        # Start and enable the service
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        
        # Create database user matching current user
        printf "Do you want to create a PostgreSQL user for your current user (${USER})? (y/n): "
        read -r CREATE_PGUSER
        if [[ "$CREATE_PGUSER" == "y" || "$CREATE_PGUSER" == "Y" ]]; then
            sudo -u postgres createuser --interactive --pwprompt "$USER"
            sudo -u postgres createdb "$USER"
            printf "${GREEN}PostgreSQL user and database created for ${USER}${NC}\n"
        fi
        
        printf "${GREEN}PostgreSQL installed and configured${NC}\n"
    else
        printf "${YELLOW}PostgreSQL is already installed${NC}\n"
    fi
fi

# Create user
printf "${BLUE}=== User setup ===${NC}\n"
printf "Do you want to create user 'berni'? (y/n): "
read -r CREATE_USER_CONFIRM
if [[ "$CREATE_USER_CONFIRM" == "y" || "$CREATE_USER_CONFIRM" == "Y" ]]; then
    create_user "berni"
fi

# Final steps
printf "${GREEN}=== Installation complete! ===${NC}\n"
printf "Note: You may need to log out and log back in for some changes to take effect.\n"
printf "To apply .Xresources, run: ${YELLOW}xrdb -merge ~/.Xresources${NC}\n"
printf "To start using tmux configuration, start a new tmux session or run: ${YELLOW}tmux source-file ~/.tmux.conf${NC}\n"
printf "To use Docker without sudo, restart your system or run: ${YELLOW}newgrp docker${NC}\n"

#!/bin/bash
# Git-crypt setup script
# Author: Bernat
# Description: Sets up git-crypt for encrypting sensitive files in the dotfiles repository

set -e

# Colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if git-crypt is installed
if ! command -v git-crypt &>/dev/null; then
    printf "${RED}git-crypt is not installed. Please install it first.${NC}\n"
    printf "On Arch Linux: sudo pacman -S git-crypt\n"
    exit 1
fi

# Check if GPG is installed
if ! command -v gpg &>/dev/null; then
    printf "${RED}GPG is not installed. Please install it first.${NC}\n"
    printf "On Arch Linux: sudo pacman -S gnupg\n"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    printf "${RED}Not in a git repository. Please run this script from your dotfiles repository.${NC}\n"
    exit 1
fi

# Welcome message
printf "${BLUE}=== Git-crypt Setup for Dotfiles ===${NC}\n"
printf "This script will set up git-crypt to encrypt sensitive files in your dotfiles repository.\n\n"

# Check if git-crypt is already initialized
if [ -d ".git-crypt" ]; then
    printf "${YELLOW}git-crypt appears to be already initialized in this repository.${NC}\n"
    printf "Do you want to continue anyway? This may overwrite existing configurations. (y/n): "
    read -r CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        printf "Aborted.\n"
        exit 0
    fi
fi

# Initialize git-crypt
printf "${BLUE}Initializing git-crypt...${NC}\n"
git-crypt init

# Create .gitattributes file if it doesn't exist
if [ ! -f ".gitattributes" ]; then
    touch .gitattributes
    printf "${GREEN}Created .gitattributes file${NC}\n"
fi

# Define patterns for files to encrypt
printf "${BLUE}Setting up patterns for files to encrypt...${NC}\n"
cat << EOF >> .gitattributes
# SSH keys and configs
.ssh/id_* filter=git-crypt diff=git-crypt
.ssh/config filter=git-crypt diff=git-crypt
.ssh/known_hosts filter=git-crypt diff=git-crypt

# AWS credentials
.aws/credentials filter=git-crypt diff=git-crypt
.aws/config filter=git-crypt diff=git-crypt

# Any other sensitive files
*.key filter=git-crypt diff=git-crypt
*.pem filter=git-crypt diff=git-crypt
*.secret filter=git-crypt diff=git-crypt
secrets/* filter=git-crypt diff=git-crypt
EOF

printf "${GREEN}Updated .gitattributes with encryption patterns${NC}\n"

# Check if the user has a GPG key
GPG_KEYS=$(gpg --list-secret-keys --keyid-format LONG)
if [ -z "$GPG_KEYS" ]; then
    printf "${YELLOW}No GPG keys found. You'll need a GPG key to unlock your encrypted files.${NC}\n"
    printf "Would you like to create a new GPG key now? (y/n): "
    read -r CREATE_KEY
    
    if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
        printf "${BLUE}Starting GPG key generation...${NC}\n"
        gpg --full-generate-key
    else
        printf "${YELLOW}Please create a GPG key and then add it to git-crypt with:${NC}\n"
        printf "git-crypt add-gpg-user YOUR_GPG_KEY_ID\n"
        exit 0
    fi
fi

# List GPG keys and ask which one to use
printf "${BLUE}Available GPG keys:${NC}\n"
gpg --list-secret-keys --keyid-format LONG

printf "\nEnter the GPG key ID to use (e.g., 1A2B3C4D5E6F7G8H): "
read -r GPG_KEY_ID

# Add the GPG key to git-crypt
printf "${BLUE}Adding GPG key to git-crypt...${NC}\n"
git-crypt add-gpg-user "$GPG_KEY_ID"

# Create directories for sensitive files if they don't exist
mkdir -p .ssh .aws secrets

# Instructions
printf "${GREEN}=== Git-crypt setup complete! ===${NC}\n\n"
printf "Files matching patterns in .gitattributes will now be encrypted when committed.\n"
printf "To unlock your repository on another machine, use:\n"
printf "  ${YELLOW}git-crypt unlock${NC}\n\n"
printf "To check if a file will be encrypted, use:\n"
printf "  ${YELLOW}git check-attr -a path/to/file${NC}\n\n"
printf "For testing, create a file named 'test.secret' and run:\n"
printf "  ${YELLOW}echo \"This is a test secret\" > test.secret${NC}\n"
printf "  ${YELLOW}git add test.secret${NC}\n"
printf "  ${YELLOW}git commit -m \"Test encrypted file\"${NC}\n\n"
printf "Then check that it appears encrypted in the repository.\n"

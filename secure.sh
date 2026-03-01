#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Installing Certbot and Nginx plugin..."
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# Prompt for domain details as this is a standalone script
read -p "Please enter your domain (e.g., domain.com): " DOMAIN

echo "Requesting SSL certificate for $DOMAIN and www.$DOMAIN..."
# This command will interactively ask for an email and agreement to terms if it's the first time
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

echo "Checking Nginx configuration file..."
# Prompt for the project name to locate the specific Nginx config file created in deploy.sh
read -p "Enter the project name (Nginx config filename): " PROJECT_NAME

if [ -f "/etc/nginx/sites-available/$PROJECT_NAME" ]; then
    cat "/etc/nginx/sites-available/$PROJECT_NAME"
else
    echo "Warning: /etc/nginx/sites-available/$PROJECT_NAME not found."
fi

echo "Testing Nginx configuration and restarting..."
sudo nginx -t
sudo systemctl restart nginx

echo "HTTPS setup is complete! Your site is now secured."
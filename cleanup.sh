#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting cleanup process..."

# Prompt for the project name (the directory name created during clone)
read -p "Enter the project directory name to remove (e.g., Blog-django): " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Project name cannot be empty. Exiting."
    exit 1
fi

echo "Stopping and disabling Gunicorn services..."
sudo systemctl stop gunicorn.socket || true
sudo systemctl disable gunicorn.socket || true
sudo systemctl stop gunicorn.service || true
sudo systemctl disable gunicorn.service || true

echo "Removing Gunicorn systemd files..."
sudo rm -f /etc/systemd/system/gunicorn.socket
sudo rm -f /etc/systemd/system/gunicorn.service

echo "Removing Nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/$PROJECT_NAME
sudo rm -f /etc/nginx/sites-available/$PROJECT_NAME

echo "Reloading systemd and restarting Nginx..."
sudo systemctl daemon-reload
sudo systemctl restart nginx

echo "Removing project directory: $PROJECT_NAME..."
if [ -d "$PROJECT_NAME" ]; then
    # Remove the directory and its contents
    rm -rf "$PROJECT_NAME"
    echo "Project directory removed."
else
    echo "Directory $PROJECT_NAME not found, skipping."
fi

echo "Cleanup complete!"
echo "Note: System-wide packages (nginx, python3-venv, etc.) were kept."
echo "If you want to remove them, run: sudo apt purge nginx python3-venv -y && sudo apt autoremove -y"
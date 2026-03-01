#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting the update process..."

# Prompt for the project directory name
read -p "Enter the project directory name to update (e.g., Blog-django): " PROJECT_NAME

if [ ! -d "$PROJECT_NAME" ]; then
    echo "Error: Directory '$PROJECT_NAME' not found."
    exit 1
fi

cd "$PROJECT_NAME"
PROJECT_DIR=$(pwd)

echo "Pulling latest changes from Git..."
git pull

echo "Activating virtual environment and updating dependencies..."
source venv/bin/activate
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

echo "Running Django management commands..."
python manage.py migrate
python manage.py collectstatic --noinput

echo "Restarting Gunicorn and Nginx..."
sudo systemctl restart gunicorn
sudo systemctl restart nginx

echo "Refreshing directory permissions..."
sudo chown -R :www-data "$PROJECT_DIR"
if [ ! -d "$PROJECT_DIR/media" ]; then
    mkdir -p "$PROJECT_DIR/media"
fi
sudo chmod -R 775 "$PROJECT_DIR/media"

echo "Update successful! Your changes are now live."

deactivate
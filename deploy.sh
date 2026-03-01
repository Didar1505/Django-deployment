#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Updating system packages..."
sudo apt update

echo "Installing required dependencies (Python, Nginx, Git)..."
sudo apt install python3-pip python3-venv nginx curl nano git -y

echo "System dependencies installed successfully."

while true; do
    # Prompt the user for the repository URL
    read -p "Please enter the public GitHub repository URL: " REPO_URL

    echo "Cloning the repository..."
    # Extract project name from URL to determine the directory name
    REPO_NAME=$(basename "$REPO_URL" .git)

    if git clone "$REPO_URL"; then
        if [ -d "$REPO_NAME" ]; then
            cd "$REPO_NAME"
            echo "Successfully cloned and entered directory: $REPO_NAME"
            pwd
            break
        fi
    fi
    echo "Failed to clone or directory '$REPO_NAME' not found. Please check the URL and try again."
done

echo "Creating virtual environment..."
python3 -m venv venv

echo "Activating virtual environment..."
source venv/bin/activate

if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt
else
    echo "requirements.txt not found. Installing basic Django stack..."
    pip install django gunicorn pillow
fi

echo "Ensuring gunicorn is installed..."
pip install gunicorn

echo "Running Django management commands..."

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Running database migrations..."
python manage.py migrate

echo "Creating superuser (requires manual input)..."
python manage.py createsuperuser

echo "Creating Gunicorn socket file..."
cat <<EOF | sudo tee /etc/systemd/system/gunicorn.socket
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
EOF

echo "Configuring Gunicorn service..."
# Get the absolute path of the project directory
PROJECT_DIR=$(pwd)

# Identify the Django project name by looking for the directory containing wsgi.py
# This assumes the standard Django structure where wsgi.py is in a subfolder
DJANGO_PROJECT_NAME=$(find . -maxdepth 2 -name wsgi.py | head -n 1 | cut -d'/' -f2)

if [ -z "$DJANGO_PROJECT_NAME" ]; then
    echo "Error: Could not find wsgi.py. Please ensure this is a standard Django project structure."
    exit 1
fi

cat <<EOF | sudo tee /etc/systemd/system/gunicorn.service
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/gunicorn \\
          --access-logfile - \\
          --workers 3 \\
          --bind unix:/run/gunicorn.sock \\
          $DJANGO_PROJECT_NAME.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Starting and enabling Gunicorn socket..."
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket

echo "Configuring Nginx..."

# Prompt for domain name
read -p "Please enter your domain name or server IP: " DOMAIN

cat <<EOF | sudo tee /etc/nginx/sites-available/$REPO_NAME
server {
    listen 80;
    server_name $DOMAIN;

    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
EOF

echo "Enabling Nginx configuration..."
sudo ln -sf /etc/nginx/sites-available/$REPO_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

echo "Testing Nginx configuration and restarting..."
sudo nginx -t
sudo systemctl restart nginx

echo "Deployment complete! Your project should be live at http://$DOMAIN"

echo "Setting final directory permissions..."
sudo chmod +x $(dirname "$PROJECT_DIR")
sudo chown -R :www-data "$PROJECT_DIR"

if [ ! -d "$PROJECT_DIR/media" ]; then
    mkdir -p "$PROJECT_DIR/media"
fi
sudo chmod -R 775 "$PROJECT_DIR/media"

echo "Permissions updated successfully."
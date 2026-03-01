# Django Production Deployment Automation

This repository contains a set of Bash scripts designed to automate the deployment, management, and securing of Django applications on Ubuntu/Debian servers using Nginx and Gunicorn.

## 🚀 Scripts Overview

| Script | Description |
| :--- | :--- |
| `deploy.sh` | Performs the initial server setup, clones the repository, configures the virtual environment, sets up Gunicorn (socket & service), and configures Nginx. |
| `secure.sh` | Installs Certbot and configures Let's Encrypt SSL certificates for HTTPS. |
| `update.sh` | Pulls the latest code from GitHub, updates dependencies, runs migrations, and restarts services. |
| `cleanup.sh` | Reverts all changes, stops services, and removes configuration files and the project directory. |

---

## 📋 Prerequisites

- A clean Ubuntu or Debian server.
- A user with `sudo` privileges.
- A public GitHub repository containing your Django project.
- A domain name pointing to your server's IP address (required for `secure.sh`).

---

## ⚙️ Django Project Configuration

Before running the `deploy.sh` script, ensure your Django `settings.py` is configured correctly to handle static files and production hosts:

```python
# settings.py

DEBUG = False  # Set to False for production
ALLOWED_HOSTS = ["mydomain.com", "www.mydomain.com", "your_server_ip"]

STATIC_URL = 'static/'
STATICFILES_DIRS = [BASE_DIR / 'static'] 
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'
```

*Note: The Nginx configuration in these scripts specifically looks for `staticfiles/` as the `STATIC_ROOT`.*

---

## 🛠️ Usage Instructions

### 1. Clone these scripts to your server
```bash
mkdir -p ~/deploy-scripts && cd ~/deploy-scripts
# Copy the scripts into this directory
```

### 2. Make the scripts executable
```bash
chmod +x deploy.sh secure.sh update.sh cleanup.sh
```

### 3. Run the Deployment
Execute the deployment script and follow the interactive prompts for your GitHub URL and Domain/IP:
```bash
./deploy.sh
```
*Note: This script will prompt you to create a Django superuser at the end.*

### 4. Secure with SSL (Optional but Recommended)
Once the site is live on HTTP, run the security script to enable HTTPS:
```bash
./secure.sh
```

### 5. Update the Project
Whenever you push new code to GitHub, run this script on the server to sync changes:
```bash
./update.sh
```

### 6. Cleanup / Teardown
If you need to remove the project and all associated configurations:
```bash
./cleanup.sh
```

---

## 🔍 What each script does in detail

### `deploy.sh`
- Updates system packages and installs `python3-pip`, `venv`, `nginx`, and `git`.
- Clones your repository and sets up a Python virtual environment.
- Installs dependencies from `requirements.txt` (or a default stack if missing).
- Runs `collectstatic` and `migrate`.
- Creates a Gunicorn socket and systemd service for process management.
- Configures an Nginx server block as a reverse proxy.
- Sets strict permissions for `www-data` and handles `media` folder creation.

### `secure.sh`
- Installs `certbot` and the Nginx plugin.
- Obtains and installs SSL certificates from Let's Encrypt.
- Automatically reloads Nginx to apply HTTPS settings.

### `update.sh`
- Pulls the latest code via `git pull`.
- Updates Python dependencies and runs database migrations.
- Restarts Gunicorn and Nginx to apply changes.
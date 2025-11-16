#!/bin/bash
# ==============================================================================
# APPLICATION DEPLOYMENT SCRIPT
# ==============================================================================
# Run this script on your AWS Lightsail instance to deploy the app
# This can be run multiple times for updates
# ==============================================================================

set -e  # Exit on any error

echo "======================================"
echo "Dating App - Deployment Script"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="$HOME/dating-app"
BACKUP_DIR="$HOME/dating-app-backups"
PACKAGE_PATTERN="dating-app-*.tar.gz"

# Find the most recent package
echo -e "${BLUE}Looking for deployment package...${NC}"
PACKAGE=$(ls -t ~/$PACKAGE_PATTERN 2>/dev/null | head -1)

if [ -z "$PACKAGE" ]; then
    echo -e "${RED}Error: No deployment package found!${NC}"
    echo "Expected file matching: ~/$PACKAGE_PATTERN"
    echo ""
    echo "Please upload your package first:"
    echo "  scp -i /path/to/key.pem dating-app-*.tar.gz ubuntu@YOUR_IP:~/"
    exit 1
fi

echo -e "${GREEN}Found package: $PACKAGE${NC}"
echo ""

# Backup existing deployment (if exists)
if [ -d "$APP_DIR" ] && [ "$(ls -A $APP_DIR)" ]; then
    echo -e "${BLUE}Backing up existing deployment...${NC}"
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    cd "$APP_DIR"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" * 2>/dev/null || true
    echo -e "${GREEN}✓ Backup created: $BACKUP_NAME${NC}"
    echo ""

    # Stop the service if running
    if systemctl is-active --quiet dating-app 2>/dev/null; then
        echo -e "${BLUE}Stopping existing service...${NC}"
        sudo systemctl stop dating-app
        echo -e "${GREEN}✓ Service stopped${NC}"
        echo ""
    fi

    # Clean app directory
    echo -e "${BLUE}Cleaning app directory...${NC}"
    rm -rf "$APP_DIR"/*
fi

# Extract new deployment
echo -e "${BLUE}Extracting new deployment...${NC}"
mkdir -p "$APP_DIR"
cd "$APP_DIR"
tar -xzf "$PACKAGE"
echo -e "${GREEN}✓ Deployment extracted${NC}"
echo ""

# Check if appsettings.Production.json exists
if [ ! -f "$APP_DIR/appsettings.Production.json" ]; then
    echo -e "${YELLOW}======================================"
    echo "Configuration Required"
    echo "======================================${NC}"
    echo ""
    echo -e "${RED}appsettings.Production.json not found!${NC}"
    echo ""
    echo "Please create the configuration file:"
    echo "  nano $APP_DIR/appsettings.Production.json"
    echo ""
    echo "Use the template from: deployment/config/appsettings.Production.json"
    echo ""
    echo "Required values:"
    echo "  - SQL Server SA password"
    echo "  - Cloudinary credentials (CloudName, ApiKey, ApiSecret)"
    echo "  - TokenKey (generate with: openssl rand -base64 64)"
    echo ""
    read -p "Press Enter after creating the file..."
fi

# Verify configuration
if [ ! -f "$APP_DIR/appsettings.Production.json" ]; then
    echo -e "${RED}Error: Configuration file still not found. Aborting.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration file found${NC}"
echo ""

# Set permissions
echo -e "${BLUE}Setting permissions...${NC}"
chmod +x "$APP_DIR/API" || true
chmod 600 "$APP_DIR/appsettings.Production.json"
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Initialize or update database
echo -e "${BLUE}Initializing database...${NC}"
echo "The app will run migrations on first startup."
echo "Starting app temporarily to initialize database..."
cd "$APP_DIR"
export ASPNETCORE_ENVIRONMENT=Production
export DOTNET_ROOT=$HOME/.dotnet

# Run app briefly to trigger migrations (will auto-exit after migrations)
timeout 30s $HOME/.dotnet/dotnet "$APP_DIR/API.dll" &
APP_PID=$!
sleep 15
kill $APP_PID 2>/dev/null || true
wait $APP_PID 2>/dev/null || true

echo -e "${GREEN}✓ Database initialized${NC}"
echo ""

# Install/update systemd service
echo -e "${BLUE}Configuring systemd service...${NC}"

# Check if service file exists
if [ ! -f "/etc/systemd/system/dating-app.service" ]; then
    echo "Installing systemd service file..."
    echo "You'll need to provide the service file content."
    echo ""
    echo "Create the service file with:"
    echo "  sudo nano /etc/systemd/system/dating-app.service"
    echo ""
    echo "Use the template from: deployment/config/dating-app.service"
    echo ""
    read -p "Press Enter after creating the service file..."

    sudo systemctl daemon-reload
    sudo systemctl enable dating-app
fi

# Start the service
echo -e "${BLUE}Starting application service...${NC}"
sudo systemctl restart dating-app
sleep 3

# Check service status
if systemctl is-active --quiet dating-app; then
    echo -e "${GREEN}✓ Service started successfully${NC}"
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo ""
    echo "Check logs with:"
    echo "  sudo journalctl -u dating-app -n 50"
    exit 1
fi

echo ""
echo -e "${GREEN}======================================"
echo "Deployment Complete!"
echo "======================================${NC}"
echo ""
echo "Service Status:"
sudo systemctl status dating-app --no-pager | head -10
echo ""
echo "Useful Commands:"
echo "  - View logs: sudo journalctl -u dating-app -f"
echo "  - Restart app: sudo systemctl restart dating-app"
echo "  - Stop app: sudo systemctl stop dating-app"
echo "  - Check SQL: sudo systemctl status mssql-server"
echo ""
echo "Your app should be running on:"
echo "  http://$(curl -s ifconfig.me):5000"
echo ""

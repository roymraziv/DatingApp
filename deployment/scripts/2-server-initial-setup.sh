#!/bin/bash
# ==============================================================================
# SERVER INITIAL SETUP SCRIPT
# ==============================================================================
# Run this script ONCE on your AWS Lightsail Ubuntu instance
# This installs all required software: .NET 9, SQL Server 2022, Nginx
# ==============================================================================

set -e  # Exit on any error

echo "======================================"
echo "Dating App - Server Initial Setup"
echo "======================================"
echo ""
echo "This script will install:"
echo "  - .NET 9 Runtime"
echo "  - SQL Server 2022 Express"
echo "  - SQL Server Command Line Tools"
echo "  - Nginx"
echo "  - Other utilities"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Update system
echo -e "${BLUE}[1/6] Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}"
echo ""

# Install .NET 9 Runtime
echo -e "${BLUE}[2/6] Installing .NET 9 Runtime...${NC}"
cd ~
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 9.0 --runtime aspnetcore --install-dir $HOME/.dotnet

# Add .NET to PATH
if ! grep -q "DOTNET_ROOT" ~/.bashrc; then
    echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
fi
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$HOME/.dotnet

# Verify .NET installation
$HOME/.dotnet/dotnet --version
echo -e "${GREEN}✓ .NET 9 installed${NC}"
echo ""

# Install SQL Server 2022
echo -e "${BLUE}[3/6] Installing SQL Server 2022 Express...${NC}"

# Import Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add SQL Server repository
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" -y

# Install SQL Server
sudo apt-get update
sudo apt-get install -y mssql-server

echo ""
echo -e "${YELLOW}======================================"
echo "SQL Server Configuration"
echo "======================================${NC}"
echo "You will now configure SQL Server."
echo "When prompted:"
echo "  1. Choose option 2 (Express - free)"
echo "  2. Accept the license terms (Yes)"
echo "  3. Set a STRONG SA password (save it!)"
echo ""
read -p "Press Enter to continue..."
echo ""

# Configure SQL Server
sudo /opt/mssql/bin/mssql-conf setup

# Enable and start SQL Server
sudo systemctl enable mssql-server
sudo systemctl start mssql-server

echo -e "${GREEN}✓ SQL Server installed and started${NC}"
echo ""

# Install SQL Server Command Line Tools
echo -e "${BLUE}[4/6] Installing SQL Server Tools...${NC}"

# Add repository for SQL tools
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

sudo apt-get update
ACCEPT_EULA=Y sudo apt-get install -y mssql-tools unixodbc-dev

# Add tools to PATH
if ! grep -q "mssql-tools" ~/.bashrc; then
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
fi
export PATH="$PATH:/opt/mssql-tools/bin"

echo -e "${GREEN}✓ SQL Server Tools installed${NC}"
echo ""

# Install Nginx
echo -e "${BLUE}[5/6] Installing Nginx...${NC}"
sudo apt-get install -y nginx
sudo systemctl enable nginx
echo -e "${GREEN}✓ Nginx installed${NC}"
echo ""

# Install useful utilities
echo -e "${BLUE}[6/6] Installing utilities...${NC}"
sudo apt-get install -y htop curl wget unzip
echo -e "${GREEN}✓ Utilities installed${NC}"
echo ""

# Create app directory
mkdir -p ~/dating-app
mkdir -p ~/dating-app-backups

echo -e "${GREEN}======================================"
echo "Initial Setup Complete!"
echo "======================================${NC}"
echo ""
echo "Installed software:"
echo "  - .NET 9 Runtime: $($HOME/.dotnet/dotnet --version)"
echo "  - SQL Server 2022 Express"
echo "  - Nginx"
echo ""
echo "Next Steps:"
echo "1. Upload your application package to this server"
echo "2. Run the deployment script (3-deploy-app.sh)"
echo ""
echo "Useful commands:"
echo "  - Check SQL Server: sudo systemctl status mssql-server"
echo "  - Check Nginx: sudo systemctl status nginx"
echo "  - View resources: htop"
echo ""

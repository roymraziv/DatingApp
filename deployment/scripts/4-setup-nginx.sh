#!/bin/bash
# ==============================================================================
# NGINX SETUP SCRIPT
# ==============================================================================
# Run this script on your AWS Lightsail instance to configure Nginx
# as a reverse proxy for your .NET application
# ==============================================================================

set -e  # Exit on any error

echo "======================================"
echo "Dating App - Nginx Setup"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${BLUE}Detected Server IP: $SERVER_IP${NC}"
echo ""

# Ask for domain or use IP
echo "Do you have a custom domain? (e.g., datingapp.example.com)"
read -p "Enter domain name or press Enter to use IP ($SERVER_IP): " DOMAIN

if [ -z "$DOMAIN" ]; then
    DOMAIN=$SERVER_IP
    echo -e "${YELLOW}Using IP address: $DOMAIN${NC}"
else
    echo -e "${GREEN}Using domain: $DOMAIN${NC}"
fi
echo ""

# Create Nginx configuration
echo -e "${BLUE}Creating Nginx configuration...${NC}"

sudo tee /etc/nginx/sites-available/dating-app > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Client max body size (for file uploads)
    client_max_body_size 10M;

    # Proxy settings
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # SignalR WebSocket support
    location /hubs/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket timeouts
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:5000;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Access and error logs
    access_log /var/log/nginx/dating-app-access.log;
    error_log /var/log/nginx/dating-app-error.log;
}
EOF

echo -e "${GREEN}✓ Nginx configuration created${NC}"
echo ""

# Enable site
echo -e "${BLUE}Enabling site...${NC}"

# Remove default site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

# Create symlink
sudo ln -sf /etc/nginx/sites-available/dating-app /etc/nginx/sites-enabled/

echo -e "${GREEN}✓ Site enabled${NC}"
echo ""

# Test Nginx configuration
echo -e "${BLUE}Testing Nginx configuration...${NC}"
sudo nginx -t

echo -e "${GREEN}✓ Configuration valid${NC}"
echo ""

# Restart Nginx
echo -e "${BLUE}Restarting Nginx...${NC}"
sudo systemctl restart nginx

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx restarted successfully${NC}"
else
    echo -e "${RED}✗ Nginx failed to start${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}======================================"
echo "Nginx Setup Complete!"
echo "======================================${NC}"
echo ""
echo "Your app is now accessible at:"
echo "  http://$DOMAIN"
echo ""

# Check if domain is not an IP
if [[ ! $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}======================================"
    echo "SSL/HTTPS Setup (Optional)"
    echo "======================================${NC}"
    echo ""
    echo "To enable HTTPS with Let's Encrypt:"
    echo ""
    echo "1. Ensure your domain DNS points to: $SERVER_IP"
    echo "2. Install certbot:"
    echo "   sudo apt install -y certbot python3-certbot-nginx"
    echo ""
    echo "3. Obtain SSL certificate:"
    echo "   sudo certbot --nginx -d $DOMAIN"
    echo ""
    echo "4. Certbot will automatically:"
    echo "   - Obtain the certificate"
    echo "   - Configure Nginx for HTTPS"
    echo "   - Set up auto-renewal"
    echo ""
fi

echo "Nginx logs:"
echo "  - Access: /var/log/nginx/dating-app-access.log"
echo "  - Error: /var/log/nginx/dating-app-error.log"
echo ""

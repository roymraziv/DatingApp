#!/bin/bash
# ==============================================================================
# RESTART SERVICES
# ==============================================================================
# Run this on your AWS Lightsail instance to restart services
# ==============================================================================

echo "======================================"
echo "Restart Services"
echo "======================================"
echo ""
echo "Select service to restart:"
echo "  1) Dating App only"
echo "  2) Nginx only"
echo "  3) SQL Server only"
echo "  4) All services"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        echo "Restarting Dating App..."
        sudo systemctl restart dating-app
        sleep 2
        sudo systemctl status dating-app --no-pager | head -10
        ;;
    2)
        echo "Restarting Nginx..."
        sudo systemctl restart nginx
        sleep 1
        sudo systemctl status nginx --no-pager | head -10
        ;;
    3)
        echo "Restarting SQL Server..."
        sudo systemctl restart mssql-server
        echo "Waiting for SQL Server to start (this may take 10-30 seconds)..."
        sleep 15
        sudo systemctl status mssql-server --no-pager | head -10
        ;;
    4)
        echo "Restarting all services..."
        echo ""
        echo "1/3 Restarting SQL Server..."
        sudo systemctl restart mssql-server
        sleep 15

        echo "2/3 Restarting Dating App..."
        sudo systemctl restart dating-app
        sleep 3

        echo "3/3 Restarting Nginx..."
        sudo systemctl restart nginx
        sleep 1

        echo ""
        echo "All services restarted. Status:"
        echo ""
        sudo systemctl status mssql-server dating-app nginx --no-pager | head -30
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Done!"

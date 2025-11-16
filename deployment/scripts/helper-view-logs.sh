#!/bin/bash
# ==============================================================================
# VIEW APPLICATION LOGS
# ==============================================================================
# Run this on your AWS Lightsail instance to view app logs
# ==============================================================================

echo "======================================"
echo "Dating App - Log Viewer"
echo "======================================"
echo ""
echo "Select log to view:"
echo "  1) Application logs (live tail)"
echo "  2) Application logs (last 100 lines)"
echo "  3) Nginx access log"
echo "  4) Nginx error log"
echo "  5) SQL Server log"
echo "  6) All services status"
echo ""
read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        echo "Following application logs (Ctrl+C to exit)..."
        sudo journalctl -u dating-app -f
        ;;
    2)
        echo "Last 100 lines of application logs:"
        sudo journalctl -u dating-app -n 100 --no-pager
        ;;
    3)
        echo "Nginx access log (last 50 lines):"
        sudo tail -50 /var/log/nginx/dating-app-access.log
        ;;
    4)
        echo "Nginx error log (last 50 lines):"
        sudo tail -50 /var/log/nginx/dating-app-error.log
        ;;
    5)
        echo "SQL Server log (last 50 lines):"
        sudo tail -50 /var/opt/mssql/log/errorlog
        ;;
    6)
        echo "Services Status:"
        echo ""
        echo "--- Dating App ---"
        sudo systemctl status dating-app --no-pager | head -15
        echo ""
        echo "--- SQL Server ---"
        sudo systemctl status mssql-server --no-pager | head -15
        echo ""
        echo "--- Nginx ---"
        sudo systemctl status nginx --no-pager | head -15
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# AWS Lightsail Deployment Guide
## Roy's .NET Dating App - Complete Step-by-Step Instructions

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [Local Preparation](#local-preparation)
4. [Server Initial Setup](#server-initial-setup)
5. [Application Deployment](#application-deployment)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance](#maintenance)

---

## Prerequisites

### Required Information
Before starting, gather the following:

- [ ] AWS Account (with billing enabled)
- [ ] Cloudinary Account (free tier)
  - [ ] Cloud Name
  - [ ] API Key
  - [ ] API Secret
- [ ] SSH Client (built into macOS/Linux, use PuTTY on Windows)
- [ ] Your local machine has: Node.js, npm, .NET 9 SDK

### Estimated Costs
- **AWS Lightsail**: $3.50/month
- **Cloudinary**: $0 (free tier)
- **Total**: $3.50/month

### Time Requirements
- **AWS Setup**: 15 minutes
- **Server Initial Setup**: 30-45 minutes
- **Application Deployment**: 30 minutes
- **Total**: ~1.5-2 hours

---

## AWS Setup

### Step 1: Create AWS Lightsail Instance

1. **Sign in to AWS Console**
   - Go to https://aws.amazon.com/
   - Sign in (or create an account if you don't have one)

2. **Navigate to Lightsail**
   - Search for "Lightsail" in the AWS Console search bar
   - Click on "Lightsail"

3. **Create Instance**
   - Click "Create instance" button

4. **Select Instance Location**
   - Choose AWS Region closest to you (or your target audience)
   - Example: `US East (N. Virginia)` or your preferred region

5. **Pick Instance Image**
   - Platform: **Linux/Unix**
   - Blueprint: **OS Only**
   - Operating System: **Ubuntu 22.04 LTS**

6. **Choose Instance Plan**
   - Select: **$3.50 USD** plan
     - 512 MB RAM
     - 1 vCPU
     - 20 GB SSD
     - 1 TB transfer

7. **Name Your Instance**
   - Name: `dating-app-prod`

8. **Create Instance**
   - Click "Create instance"
   - Wait 2-3 minutes for instance to start

### Step 2: Configure Firewall

1. **Open Instance Details**
   - Click on your instance name

2. **Go to Networking Tab**
   - Click "Networking" tab

3. **Add Firewall Rules**
   - Click "Add rule" and create these rules:

   | Application | Protocol | Port Range |
   |-------------|----------|------------|
   | Custom      | TCP      | 5000       |
   | HTTP        | TCP      | 80         |
   | HTTPS       | TCP      | 443        |

   (SSH on port 22 is already there)

4. **Save**

### Step 3: Attach Static IP

1. **In Networking Tab**
   - Scroll to "IPv4 Public IP"
   - Click "Create static IP"

2. **Attach to Instance**
   - Select your instance: `dating-app-prod`
   - Name: `dating-app-static-ip`
   - Click "Create"

3. **Note Your Static IP**
   - **Write down this IP address** - you'll need it throughout deployment
   - Example: `3.86.123.456`

### Step 4: Download SSH Key

1. **Go to Account Tab**
   - Click "Account" in top menu
   - Click "SSH keys"

2. **Download Key**
   - Find your region's default key
   - Click "Download"
   - Save as: `LightsailDefaultKey.pem`
   - Move to safe location (e.g., `~/.ssh/`)

3. **Set Permissions** (macOS/Linux)
   ```bash
   chmod 400 ~/.ssh/LightsailDefaultKey.pem
   ```

---

## Local Preparation

### Step 1: Prepare Deployment Scripts

All scripts are already in the `deployment/` folder. Make them executable:

```bash
cd /home/user/DatingApp/deployment/scripts
chmod +x *.sh
```

### Step 2: Generate Token Key

Generate a secure key for JWT authentication:

```bash
cd /home/user/DatingApp/deployment/scripts
./helper-generate-token-key.sh
```

**Copy the output** - you'll need it for `appsettings.Production.json`

### Step 3: Update CORS Origins

Update your app to allow requests from your AWS server:

```bash
cd /home/user/DatingApp/deployment/scripts
./5-update-cors.sh
```

When prompted, enter your **AWS Static IP** from Step 3 above.

### Step 4: Create Production Configuration

1. **Copy the template**:
   ```bash
   cd /home/user/DatingApp/deployment/config
   cp appsettings.Production.json ~/appsettings.Production.json.temp
   ```

2. **Edit the file**:
   ```bash
   nano ~/appsettings.Production.json.temp
   ```

3. **Fill in these values**:

   | Field | Value | Where to Get It |
   |-------|-------|-----------------|
   | SQL Password | Strong password (create one) | You'll use this in server setup |
   | CloudName | Your Cloudinary cloud name | Cloudinary Dashboard |
   | ApiKey | Your Cloudinary API key | Cloudinary Dashboard |
   | ApiSecret | Your Cloudinary API secret | Cloudinary Dashboard |
   | TokenKey | Generated key | From Step 2 above |

   Example:
   ```json
   {
     "Logging": {
       "LogLevel": {
         "Default": "Information",
         "Microsoft.AspNetCore": "Warning"
       }
     },
     "AllowedHosts": "*",
     "ConnectionStrings": {
       "DefaultConnection": "Server=localhost;Database=DatingDB;User Id=SA;Password=MyStr0ngP@ssw0rd123!;TrustServerCertificate=True;Encrypt=False;"
     },
     "CloudinarySettings": {
       "CloudName": "dxxxxxxxx",
       "ApiKey": "123456789012345",
       "ApiSecret": "abcdefghijklmnopqrstuvwxyz123456"
     },
     "TokenKey": "your-generated-token-key-from-step-2"
   }
   ```

4. **Save** (Ctrl+X, then Y, then Enter)

### Step 5: Build and Package Application

Run the build script:

```bash
cd /home/user/DatingApp/deployment/scripts
./1-local-build.sh
```

This will:
- Build Angular frontend
- Publish .NET backend
- Create deployment package (e.g., `dating-app-20241116-143000.tar.gz`)

**Note the package name** - you'll upload this to the server.

---

## Server Initial Setup

### Step 1: Connect to Your Server

**Option A: Browser SSH** (Easiest)
1. Go to AWS Lightsail Console
2. Click on your instance
3. Click "Connect using SSH" button

**Option B: SSH from Terminal**
```bash
ssh -i ~/.ssh/LightsailDefaultKey.pem ubuntu@YOUR_STATIC_IP
```

Replace `YOUR_STATIC_IP` with your actual IP.

### Step 2: Upload Setup Script

From your **local machine**, upload the setup script:

```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/2-server-initial-setup.sh \
    ubuntu@YOUR_STATIC_IP:~/
```

### Step 3: Run Initial Setup Script

On the **server** (after SSH):

```bash
chmod +x ~/2-server-initial-setup.sh
./2-server-initial-setup.sh
```

**What happens**:
1. System updates
2. .NET 9 installation
3. SQL Server 2022 Express installation (you'll be prompted)
4. SQL Server tools installation
5. Nginx installation

**During SQL Server setup**:
- Choose option **2** (Express - free)
- Accept license: **Yes**
- Enter SA password: Use the **same password** you put in `appsettings.Production.json`

This takes ~20-30 minutes.

### Step 4: Verify Installation

After the script completes:

```bash
# Check .NET
dotnet --version

# Check SQL Server
sudo systemctl status mssql-server

# Check Nginx
sudo systemctl status nginx
```

All should show as "active (running)".

---

## Application Deployment

### Step 1: Upload Application Package

From your **local machine**:

```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/publish/dating-app-*.tar.gz \
    ubuntu@YOUR_STATIC_IP:~/
```

### Step 2: Upload Configuration File

Upload your production settings:

```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    ~/appsettings.Production.json.temp \
    ubuntu@YOUR_STATIC_IP:~/appsettings.Production.json
```

### Step 3: Upload Deployment Script

```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/3-deploy-app.sh \
    ubuntu@YOUR_STATIC_IP:~/
```

### Step 4: Upload Service Configuration

```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/config/dating-app.service \
    ubuntu@YOUR_STATIC_IP:~/
```

### Step 5: Move Configuration Files

On the **server**:

```bash
# Install systemd service
sudo cp ~/dating-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dating-app
```

### Step 6: Run Deployment Script

On the **server**:

```bash
chmod +x ~/3-deploy-app.sh
./3-deploy-app.sh
```

**What happens**:
1. Extracts application
2. Finds your `appsettings.Production.json`
3. Initializes database (runs migrations)
4. Starts the application service

**Verify**:
```bash
sudo systemctl status dating-app
```

Should show "active (running)".

**Test the API**:
```bash
curl http://localhost:5000
```

Should return HTML from your Angular app.

---

## Post-Deployment Configuration

### Step 1: Setup Nginx Reverse Proxy

Upload Nginx setup script:

From **local machine**:
```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/4-setup-nginx.sh \
    ubuntu@YOUR_STATIC_IP:~/
```

On the **server**:
```bash
chmod +x ~/4-setup-nginx.sh
./4-setup-nginx.sh
```

When prompted:
- Enter your **Static IP** or domain name (if you have one)

This configures Nginx as a reverse proxy.

### Step 2: Test Your Application

1. **Open browser**
2. **Navigate to**: `http://YOUR_STATIC_IP`
3. **You should see your Dating App homepage!**

### Step 3: Test Key Features

- [ ] Homepage loads
- [ ] Register new account
- [ ] Login works
- [ ] Upload photo (Cloudinary integration)
- [ ] Browse members
- [ ] Send message (SignalR)

---

## Optional: SSL/HTTPS Setup

If you have a custom domain:

### Step 1: Point Domain to Server

In your domain registrar (GoDaddy, Namecheap, etc.):
- Create an A record pointing to your Static IP

### Step 2: Install Certbot

On the **server**:
```bash
sudo apt install -y certbot python3-certbot-nginx
```

### Step 3: Obtain SSL Certificate

```bash
sudo certbot --nginx -d yourdomain.com
```

Follow prompts:
- Enter email
- Agree to terms
- Choose to redirect HTTP to HTTPS (recommended)

Certbot will automatically:
- Obtain SSL certificate
- Configure Nginx for HTTPS
- Setup auto-renewal

---

## Troubleshooting

### Application Won't Start

**Check logs**:
```bash
sudo journalctl -u dating-app -n 100
```

**Common issues**:

1. **Configuration errors**
   - Verify `appsettings.Production.json` is correct
   - Check SQL password matches

2. **SQL Server connection**
   ```bash
   sudo systemctl status mssql-server
   # If not running:
   sudo systemctl start mssql-server
   ```

3. **Port already in use**
   ```bash
   sudo lsof -i :5000
   # Kill conflicting process or change port
   ```

### Database Issues

**Connect to SQL Server**:
```bash
sqlcmd -S localhost -U SA -P 'YourPassword'
```

**List databases**:
```sql
SELECT name FROM sys.databases;
GO
```

**Check tables**:
```sql
USE DatingDB;
GO
SELECT * FROM INFORMATION_SCHEMA.TABLES;
GO
```

### Nginx Issues

**Test configuration**:
```bash
sudo nginx -t
```

**View error logs**:
```bash
sudo tail -50 /var/log/nginx/dating-app-error.log
```

**Restart Nginx**:
```bash
sudo systemctl restart nginx
```

### Out of Memory

If you see memory errors:

1. **Check memory usage**:
   ```bash
   free -h
   htop  # (press q to quit)
   ```

2. **Add swap file** (if needed):
   ```bash
   sudo fallocate -l 1G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile

   # Make permanent
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

### Application Logs

Use the helper script:

Upload from **local machine**:
```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/helper-view-logs.sh \
    ubuntu@YOUR_STATIC_IP:~/
```

On **server**:
```bash
chmod +x ~/helper-view-logs.sh
./helper-view-logs.sh
```

---

## Maintenance

### Restart Services

Upload helper script from **local machine**:
```bash
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/helper-restart-services.sh \
    ubuntu@YOUR_STATIC_IP:~/
```

On **server**:
```bash
chmod +x ~/helper-restart-services.sh
./helper-restart-services.sh
```

### Deploy Updates

When you make changes to your app:

1. **On local machine**:
   ```bash
   cd /home/user/DatingApp/deployment/scripts
   ./1-local-build.sh
   ```

2. **Upload new package**:
   ```bash
   scp -i ~/.ssh/LightsailDefaultKey.pem \
       /home/user/DatingApp/publish/dating-app-*.tar.gz \
       ubuntu@YOUR_STATIC_IP:~/
   ```

3. **On server**:
   ```bash
   ./3-deploy-app.sh
   ```

The script automatically:
- Backs up current deployment
- Stops the service
- Deploys new version
- Restarts the service

### Backup Database

**Manual backup**:
```bash
sqlcmd -S localhost -U SA -P 'YourPassword' -Q \
  "BACKUP DATABASE DatingDB TO DISK='/home/ubuntu/dating-app-backups/DatingDB-$(date +%Y%m%d).bak'"
```

**Automated daily backups** (optional):

Create backup script:
```bash
nano ~/backup-database.sh
```

Add:
```bash
#!/bin/bash
sqlcmd -S localhost -U SA -P 'YourPassword' -Q \
  "BACKUP DATABASE DatingDB TO DISK='/home/ubuntu/dating-app-backups/DatingDB-$(date +%Y%m%d).bak' WITH INIT"

# Delete backups older than 7 days
find /home/ubuntu/dating-app-backups -name "*.bak" -mtime +7 -delete
```

Make executable:
```bash
chmod +x ~/backup-database.sh
```

Add to cron (runs daily at 2 AM):
```bash
crontab -e
```

Add this line:
```
0 2 * * * /home/ubuntu/backup-database.sh
```

### Monitor Resources

**Real-time monitoring**:
```bash
htop
```

**Disk usage**:
```bash
df -h
```

**Check what's using space**:
```bash
du -sh /home/ubuntu/* | sort -h
```

### System Updates

**Monthly maintenance**:
```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

**After updates, restart services**:
```bash
sudo systemctl restart dating-app
```

---

## Quick Reference

### Important File Locations

| Item | Location |
|------|----------|
| Application | `/home/ubuntu/dating-app/` |
| App Config | `/home/ubuntu/dating-app/appsettings.Production.json` |
| Service File | `/etc/systemd/system/dating-app.service` |
| Nginx Config | `/etc/nginx/sites-available/dating-app` |
| App Logs | `sudo journalctl -u dating-app` |
| Nginx Logs | `/var/log/nginx/dating-app-*.log` |
| SQL Server Logs | `/var/opt/mssql/log/errorlog` |
| Backups | `/home/ubuntu/dating-app-backups/` |

### Common Commands

```bash
# View app logs (live)
sudo journalctl -u dating-app -f

# Restart app
sudo systemctl restart dating-app

# Check app status
sudo systemctl status dating-app

# Restart Nginx
sudo systemctl restart nginx

# Restart SQL Server
sudo systemctl restart mssql-server

# Connect to database
sqlcmd -S localhost -U SA -P 'YourPassword'

# Check resource usage
htop

# Check disk space
df -h
```

### Cost Monitoring

**AWS Lightsail Billing**:
- Go to AWS Console → Billing Dashboard
- Expected monthly cost: **$3.50**
- No data transfer charges (1TB included)

**Set up billing alert** (recommended):
1. AWS Console → Billing → Billing preferences
2. Enable "Receive Billing Alerts"
3. CloudWatch → Create alarm for $5 threshold

---

## Security Best Practices

### 1. Change Default Passwords

After initial setup:
```bash
# Change Ubuntu user password
passwd
```

### 2. Disable Root Login (Optional)

Edit SSH config:
```bash
sudo nano /etc/ssh/sshd_config
```

Set:
```
PermitRootLogin no
PasswordAuthentication no
```

Restart SSH:
```bash
sudo systemctl restart ssh
```

### 3. Enable Firewall (UFW)

```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 5000  # App (if needed)
sudo ufw enable
```

### 4. Keep Secrets Secret

- Never commit `appsettings.Production.json` to git
- Use strong passwords (12+ characters, mixed case, numbers, symbols)
- Rotate Cloudinary API keys periodically

### 5. Regular Updates

```bash
# Weekly:
sudo apt update && sudo apt upgrade -y
```

---

## Success Checklist

After deployment, verify:

- [ ] Application accessible at `http://YOUR_IP`
- [ ] Can register new user
- [ ] Can login
- [ ] Can upload photo (Cloudinary working)
- [ ] Can view members
- [ ] Can send messages (SignalR working)
- [ ] HTTPS working (if configured)
- [ ] All services start on reboot
- [ ] Logs are clean (no errors)

---

## Getting Help

### Check Logs First

1. **Application logs**: `sudo journalctl -u dating-app -n 100`
2. **Nginx logs**: `sudo tail -100 /var/log/nginx/dating-app-error.log`
3. **SQL Server logs**: `sudo tail -100 /var/opt/mssql/log/errorlog`

### Common Error Messages

| Error | Solution |
|-------|----------|
| "Connection refused" | Check if service is running: `sudo systemctl status dating-app` |
| "Cannot connect to SQL Server" | Verify SQL Server running: `sudo systemctl status mssql-server` |
| "502 Bad Gateway" | App isn't running, check app logs |
| "413 Request Entity Too Large" | Increase `client_max_body_size` in Nginx config |

---

## Conclusion

You now have a production-ready .NET + Angular application running on AWS Lightsail for $3.50/month!

### What You've Accomplished:
- ✅ Deployed full-stack application to AWS
- ✅ Configured SQL Server database
- ✅ Set up Nginx reverse proxy
- ✅ Integrated external services (Cloudinary)
- ✅ Implemented real-time features (SignalR)
- ✅ Production-grade configuration

### Portfolio Benefits:
- Demonstrates cloud deployment skills (AWS)
- Shows Linux server administration
- Proves full-stack capabilities (.NET + Angular)
- Highlights DevOps knowledge (systemd, Nginx, CI/CD concepts)

**Share your deployed app**: `http://YOUR_STATIC_IP`

Good luck with your portfolio! 🚀

# AWS Deployment Checklist

Print this or keep it open while deploying!

---

## Pre-Deployment Preparation

### Required Accounts & Credentials
- [ ] AWS account created
- [ ] AWS billing enabled
- [ ] Cloudinary account created (free tier)
- [ ] Cloudinary Cloud Name: `________________`
- [ ] Cloudinary API Key: `________________`
- [ ] Cloudinary API Secret: `________________`

### Tools Installed Locally
- [ ] Node.js and npm
- [ ] .NET 9 SDK
- [ ] SSH client
- [ ] openssl (for token generation)

---

## AWS Lightsail Setup

### Instance Creation
- [ ] Logged into AWS Console
- [ ] Navigated to Lightsail
- [ ] Created instance:
  - [ ] Region selected: `________________`
  - [ ] Platform: Linux/Unix
  - [ ] OS: Ubuntu 22.04 LTS
  - [ ] Plan: $3.50/month (512MB RAM)
  - [ ] Instance name: `dating-app-prod`
  - [ ] Instance created and running

### Networking Configuration
- [ ] Firewall rules added:
  - [ ] SSH (22) - already there
  - [ ] HTTP (80)
  - [ ] HTTPS (443)
  - [ ] Custom TCP (5000)

### Static IP
- [ ] Static IP created
- [ ] Static IP attached to instance
- [ ] Static IP noted: `___.___.___.___`

### SSH Access
- [ ] SSH key downloaded: `LightsailDefaultKey.pem`
- [ ] SSH key moved to: `~/.ssh/`
- [ ] SSH key permissions set: `chmod 400`
- [ ] SSH connection tested: `ssh -i ~/.ssh/LightsailDefaultKey.pem ubuntu@IP`

---

## Local Preparation

### Configuration
- [ ] Scripts made executable: `chmod +x deployment/scripts/*.sh`
- [ ] Token key generated: `./helper-generate-token-key.sh`
- [ ] Token key saved: `________________`
- [ ] SQL Server password created (strong): `________________`
- [ ] CORS origins updated: `./5-update-cors.sh`
- [ ] Production config created: `appsettings.Production.json`
- [ ] Production config filled with:
  - [ ] SQL Server password
  - [ ] Cloudinary CloudName
  - [ ] Cloudinary ApiKey
  - [ ] Cloudinary ApiSecret
  - [ ] TokenKey

### Build Application
- [ ] Build script executed: `./1-local-build.sh`
- [ ] Build completed successfully
- [ ] Package created: `dating-app-YYYYMMDD-HHMMSS.tar.gz`
- [ ] Package location noted: `________________`

---

## Server Initial Setup

### Upload Setup Script
- [ ] Script uploaded to server:
  ```bash
  scp -i ~/.ssh/LightsailDefaultKey.pem \
      deployment/scripts/2-server-initial-setup.sh \
      ubuntu@YOUR_IP:~/
  ```

### Run Setup Script
- [ ] SSH'd into server
- [ ] Script made executable: `chmod +x ~/2-server-initial-setup.sh`
- [ ] Script executed: `./2-server-initial-setup.sh`
- [ ] System updated
- [ ] .NET 9 installed
- [ ] SQL Server 2022 installed:
  - [ ] Express edition selected
  - [ ] License accepted
  - [ ] SA password set (same as in config)
  - [ ] SQL Server started
- [ ] SQL Server tools installed
- [ ] Nginx installed
- [ ] Utilities installed

### Verify Installation
- [ ] .NET version checked: `dotnet --version`
- [ ] SQL Server status: `sudo systemctl status mssql-server` (active)
- [ ] Nginx status: `sudo systemctl status nginx` (active)

---

## Application Deployment

### Upload Files
- [ ] Application package uploaded:
  ```bash
  scp -i ~/.ssh/key.pem publish/dating-app-*.tar.gz ubuntu@IP:~/
  ```
- [ ] Configuration file uploaded:
  ```bash
  scp -i ~/.ssh/key.pem appsettings.Production.json ubuntu@IP:~/
  ```
- [ ] Deployment script uploaded:
  ```bash
  scp -i ~/.ssh/key.pem deployment/scripts/3-deploy-app.sh ubuntu@IP:~/
  ```
- [ ] Service file uploaded:
  ```bash
  scp -i ~/.ssh/key.pem deployment/config/dating-app.service ubuntu@IP:~/
  ```

### Configure Service
- [ ] Service file copied: `sudo cp ~/dating-app.service /etc/systemd/system/`
- [ ] Systemd reloaded: `sudo systemctl daemon-reload`
- [ ] Service enabled: `sudo systemctl enable dating-app`

### Deploy Application
- [ ] Deployment script made executable: `chmod +x ~/3-deploy-app.sh`
- [ ] Deployment script executed: `./3-deploy-app.sh`
- [ ] Application extracted
- [ ] Database initialized (migrations run)
- [ ] Service started
- [ ] Service status verified: `sudo systemctl status dating-app` (active)

### Test Backend
- [ ] API responding: `curl http://localhost:5000`
- [ ] Returns HTML content

---

## Nginx Configuration

### Upload and Run Script
- [ ] Nginx setup script uploaded:
  ```bash
  scp -i ~/.ssh/key.pem deployment/scripts/4-setup-nginx.sh ubuntu@IP:~/
  ```
- [ ] Script made executable: `chmod +x ~/4-setup-nginx.sh`
- [ ] Script executed: `./4-setup-nginx.sh`
- [ ] Domain/IP entered when prompted
- [ ] Nginx config created
- [ ] Nginx config tested: `sudo nginx -t`
- [ ] Nginx restarted
- [ ] Nginx status: `sudo systemctl status nginx` (active)

---

## Testing & Verification

### Basic Tests
- [ ] Application accessible in browser: `http://YOUR_IP`
- [ ] Homepage loads correctly
- [ ] Angular app renders

### Feature Tests
- [ ] User registration works
- [ ] User login works
- [ ] Photo upload works (Cloudinary integration)
- [ ] Browse members works
- [ ] Messaging works (SignalR)
- [ ] Real-time presence works

### Technical Verification
- [ ] All services running:
  - [ ] dating-app: `sudo systemctl status dating-app`
  - [ ] mssql-server: `sudo systemctl status mssql-server`
  - [ ] nginx: `sudo systemctl status nginx`
- [ ] No errors in logs: `sudo journalctl -u dating-app -n 50`
- [ ] Database tables created: `sqlcmd -S localhost -U SA -P 'password'`

---

## Optional: SSL/HTTPS Setup

(Skip if using IP only)

### Prerequisites
- [ ] Custom domain purchased
- [ ] DNS A record created pointing to Static IP
- [ ] DNS propagated (check: `nslookup yourdomain.com`)

### SSL Certificate
- [ ] Certbot installed: `sudo apt install -y certbot python3-certbot-nginx`
- [ ] Certificate obtained: `sudo certbot --nginx -d yourdomain.com`
- [ ] Email entered
- [ ] Terms accepted
- [ ] HTTP to HTTPS redirect enabled
- [ ] Certificate obtained successfully
- [ ] HTTPS accessible: `https://yourdomain.com`
- [ ] Auto-renewal configured

---

## Post-Deployment Tasks

### Upload Helper Scripts
- [ ] Log viewer uploaded:
  ```bash
  scp -i ~/.ssh/key.pem deployment/scripts/helper-view-logs.sh ubuntu@IP:~/
  ```
- [ ] Service restart script uploaded:
  ```bash
  scp -i ~/.ssh/key.pem deployment/scripts/helper-restart-services.sh ubuntu@IP:~/
  ```
- [ ] Scripts made executable: `chmod +x ~/helper-*.sh`

### Documentation
- [ ] Static IP documented in safe place
- [ ] SQL Server password saved in password manager
- [ ] Cloudinary credentials saved
- [ ] TokenKey saved securely
- [ ] SSH key backed up

### Security
- [ ] appsettings.Production.json NOT committed to git
- [ ] SSH key has proper permissions (400)
- [ ] SQL Server password is strong
- [ ] Consider enabling UFW firewall (optional)

### Monitoring Setup
- [ ] Bookmarked AWS Lightsail console
- [ ] AWS billing alert set up ($5 threshold)
- [ ] Tested viewing logs: `./helper-view-logs.sh`
- [ ] Tested restarting services: `./helper-restart-services.sh`

---

## Final Verification

### Functionality Checklist
- [ ] Can register new user
- [ ] Can login
- [ ] Can upload profile photo
- [ ] Can edit profile
- [ ] Can view other members
- [ ] Can like members
- [ ] Can send messages
- [ ] Can receive messages (real-time)
- [ ] Can see online users (presence)

### Performance Check
- [ ] Page load time acceptable (<3 seconds)
- [ ] Images load from Cloudinary
- [ ] SignalR connects successfully
- [ ] No JavaScript errors in browser console

### Services Auto-Start
- [ ] Reboot server: `sudo reboot`
- [ ] Wait 2 minutes
- [ ] Reconnect via SSH
- [ ] Verify all services auto-started:
  - [ ] `sudo systemctl status dating-app`
  - [ ] `sudo systemctl status mssql-server`
  - [ ] `sudo systemctl status nginx`
- [ ] App still accessible in browser

---

## Deployment Complete! 🎉

### Share Your Work
- [ ] Add to portfolio website
- [ ] Update resume with:
  - AWS Lightsail deployment
  - Linux server administration
  - .NET Core production deployment
  - Nginx configuration
- [ ] Add to LinkedIn projects
- [ ] Share with recruiters: `http://YOUR_STATIC_IP`

### URL to Share
```
http://___.___.___.___
```

### Monthly Cost
```
AWS Lightsail:    $3.50
Cloudinary:       $0.00
-----------------------
Total:            $3.50/month
```

---

## Maintenance Schedule

### Weekly
- [ ] Check application logs for errors
- [ ] Verify all services running
- [ ] Check disk space: `df -h`

### Monthly
- [ ] System updates: `sudo apt update && sudo apt upgrade -y`
- [ ] Restart services after updates
- [ ] Review AWS billing

### As Needed
- [ ] Deploy code updates using scripts 1 and 3
- [ ] Backup database (see DEPLOYMENT_GUIDE.md)

---

## Quick Command Reference

```bash
# View live logs
sudo journalctl -u dating-app -f

# Restart app
sudo systemctl restart dating-app

# Restart Nginx
sudo systemctl restart nginx

# Check all services
sudo systemctl status dating-app mssql-server nginx

# Monitor resources
htop

# Check disk space
df -h

# Connect to database
sqlcmd -S localhost -U SA -P 'YourPassword'
```

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Static IP**: _______________
**Domain** (if any): _______________

---

Keep this checklist for reference and for future redeployments!

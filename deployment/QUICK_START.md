# Quick Start Guide - AWS Deployment

This is the **TL;DR version**. For detailed instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

---

## Prerequisites

- AWS Account
- Cloudinary account (free)
- Your local machine has: Node.js, npm, .NET 9 SDK

---

## 5-Minute Overview

### Phase 1: AWS Setup (15 min)

1. **Create Lightsail Instance**
   - Go to AWS Lightsail
   - Create Ubuntu 22.04 instance ($3.50/month plan)
   - Name: `dating-app-prod`

2. **Configure Networking**
   - Add firewall rules: ports 80, 443, 5000
   - Create and attach static IP
   - Download SSH key

3. **Note your Static IP**: `___.___.___,___`

### Phase 2: Local Prep (30 min)

```bash
cd /home/user/DatingApp/deployment/scripts

# 1. Make scripts executable
chmod +x *.sh

# 2. Generate token key (save output!)
./helper-generate-token-key.sh

# 3. Update CORS with your AWS IP
./5-update-cors.sh

# 4. Create production config (edit with your values)
nano ../config/appsettings.Production.json
# Fill in: SQL password, Cloudinary credentials, TokenKey

# 5. Build application
./1-local-build.sh
```

### Phase 3: Server Setup (45 min)

```bash
# SSH into server
ssh -i ~/.ssh/LightsailDefaultKey.pem ubuntu@YOUR_STATIC_IP

# Upload and run setup script (from local machine)
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/2-server-initial-setup.sh \
    ubuntu@YOUR_STATIC_IP:~/

# On server
chmod +x ~/2-server-initial-setup.sh
./2-server-initial-setup.sh
# Follow prompts (choose Express edition for SQL Server)
```

### Phase 4: Deploy App (30 min)

```bash
# From local machine, upload files
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/publish/dating-app-*.tar.gz \
    ubuntu@YOUR_STATIC_IP:~/

scp -i ~/.ssh/LightsailDefaultKey.pem \
    ~/appsettings.Production.json.temp \
    ubuntu@YOUR_STATIC_IP:~/appsettings.Production.json

scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/3-deploy-app.sh \
    ubuntu@YOUR_STATIC_IP:~/

scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/config/dating-app.service \
    ubuntu@YOUR_STATIC_IP:~/

# On server, setup systemd service
sudo cp ~/dating-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dating-app

# Deploy app
chmod +x ~/3-deploy-app.sh
./3-deploy-app.sh
```

### Phase 5: Setup Nginx (15 min)

```bash
# Upload nginx setup script
scp -i ~/.ssh/LightsailDefaultKey.pem \
    /home/user/DatingApp/deployment/scripts/4-setup-nginx.sh \
    ubuntu@YOUR_STATIC_IP:~/

# On server
chmod +x ~/4-setup-nginx.sh
./4-setup-nginx.sh
# Enter your static IP when prompted
```

### Done! 🎉

Visit: `http://YOUR_STATIC_IP`

---

## Troubleshooting

**App not starting?**
```bash
sudo journalctl -u dating-app -n 100
```

**Database issues?**
```bash
sudo systemctl status mssql-server
```

**Nginx problems?**
```bash
sudo nginx -t
sudo tail -50 /var/log/nginx/dating-app-error.log
```

---

## Deployment Checklist

### Before You Start
- [ ] AWS account created
- [ ] Cloudinary credentials ready
- [ ] SSH key downloaded
- [ ] Static IP noted

### Configuration
- [ ] TokenKey generated
- [ ] CORS origins updated
- [ ] appsettings.Production.json created
- [ ] Application built

### Server Setup
- [ ] Lightsail instance created
- [ ] Firewall configured
- [ ] .NET 9 installed
- [ ] SQL Server installed
- [ ] Nginx installed

### Deployment
- [ ] Application uploaded
- [ ] Configuration uploaded
- [ ] Systemd service configured
- [ ] App service running
- [ ] Nginx configured

### Verification
- [ ] App accessible via browser
- [ ] Can register user
- [ ] Can login
- [ ] Can upload photo
- [ ] Can send message

---

## Quick Commands Reference

```bash
# View logs
sudo journalctl -u dating-app -f

# Restart app
sudo systemctl restart dating-app

# Check status
sudo systemctl status dating-app

# Monitor resources
htop

# Connect to database
sqlcmd -S localhost -U SA -P 'YourPassword'
```

---

## Monthly Costs

- AWS Lightsail: **$3.50**
- Cloudinary: **$0** (free tier)
- **Total: $3.50/month**

---

## Need More Help?

See the full [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for:
- Detailed troubleshooting
- Security best practices
- SSL/HTTPS setup
- Backup strategies
- Maintenance procedures

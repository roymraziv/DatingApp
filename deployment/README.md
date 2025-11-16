# AWS Deployment Package

Complete deployment solution for Roy's .NET Dating App to AWS Lightsail.

**Cost**: $3.50/month | **Time**: ~2 hours

---

## 📁 Directory Structure

```
deployment/
├── README.md                          # This file
├── DEPLOYMENT_GUIDE.md                # Complete step-by-step guide
├── QUICK_START.md                     # Quick reference
│
├── scripts/                           # Deployment scripts
│   ├── 1-local-build.sh              # Build app locally
│   ├── 2-server-initial-setup.sh     # Install .NET, SQL Server, Nginx
│   ├── 3-deploy-app.sh               # Deploy application to server
│   ├── 4-setup-nginx.sh              # Configure Nginx reverse proxy
│   ├── 5-update-cors.sh              # Update CORS origins
│   ├── helper-generate-token-key.sh  # Generate JWT token key
│   ├── helper-view-logs.sh           # View application logs
│   └── helper-restart-services.sh    # Restart services
│
└── config/                            # Configuration templates
    ├── appsettings.Production.json   # App configuration template
    ├── dating-app.service            # Systemd service file
    └── nginx-dating-app.conf         # Nginx configuration template
```

---

## 🚀 Getting Started

### Choose Your Path:

**🌟 RECOMMENDED FOR MOST USERS:**

1. **Want the easiest way? (Web browser only, no CLI tools)**
   → Start with [ULTRA_SIMPLE.md](ULTRA_SIMPLE.md) - Just copy/paste!

2. **Prefer web interface with detailed steps?**
   → Use [SIMPLE_WEB_DEPLOYMENT.md](SIMPLE_WEB_DEPLOYMENT.md)

**For Advanced Users:**

3. **Comfortable with command-line and want automation?**
   → Use scripts and read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

4. **Experienced with deployments?**
   → Use [QUICK_START.md](QUICK_START.md)

5. **Just want to update your app?**
   → Run scripts 1 and 3 only

---

## 📖 Documentation

### [ULTRA_SIMPLE.md](ULTRA_SIMPLE.md) ⭐ RECOMMENDED
**The easiest way to deploy** - No CLI tools needed!
- Everything done through AWS web interface
- Copy-paste commands into browser SSH
- Minimal steps (5 main steps)
- ~45 minutes total time
- Perfect for beginners

**Read this if**: You want the simplest, fastest deployment with minimal hassle.

### [SIMPLE_WEB_DEPLOYMENT.md](SIMPLE_WEB_DEPLOYMENT.md)
Web-based deployment with more details:
- Uses AWS web console (no downloads)
- Browser-based SSH terminal
- Step-by-step with explanations
- ~1 hour total time
- Good for first-time deployers who want to understand each step

**Read this if**: You prefer detailed explanations but still want to avoid complex CLI tools.

### [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
Complete, detailed guide using automation scripts:
- Prerequisites checklist
- AWS Lightsail setup
- Automated scripts for setup
- Comprehensive troubleshooting
- Maintenance procedures
- Security best practices

**Read this if**: You're comfortable with CLI and want automated deployment scripts.

### [QUICK_START.md](QUICK_START.md)
Condensed reference for experienced users:
- Command cheat sheet
- Quick deployment checklist
- Common commands

**Read this if**: You've deployed before and just need a quick reminder.

---

## 🛠 Scripts Overview

### Deployment Scripts (Run in Order)

#### 1️⃣ `1-local-build.sh`
**Run on**: Your local machine
**Purpose**: Build Angular frontend and publish .NET backend
**Output**: `dating-app-YYYYMMDD-HHMMSS.tar.gz`

```bash
cd /home/user/DatingApp/deployment/scripts
./1-local-build.sh
```

#### 2️⃣ `2-server-initial-setup.sh`
**Run on**: AWS Lightsail instance (once only)
**Purpose**: Install .NET 9, SQL Server 2022, Nginx
**Time**: ~30 minutes

```bash
# Upload to server first
scp -i ~/.ssh/key.pem 2-server-initial-setup.sh ubuntu@IP:~/
# Then run on server
./2-server-initial-setup.sh
```

#### 3️⃣ `3-deploy-app.sh`
**Run on**: AWS Lightsail instance
**Purpose**: Extract and deploy application, start services
**Time**: ~5 minutes
**Note**: Can be run multiple times for updates

```bash
./3-deploy-app.sh
```

#### 4️⃣ `4-setup-nginx.sh`
**Run on**: AWS Lightsail instance (once only)
**Purpose**: Configure Nginx as reverse proxy
**Time**: ~2 minutes

```bash
./4-setup-nginx.sh
```

#### 5️⃣ `5-update-cors.sh`
**Run on**: Your local machine (before building)
**Purpose**: Update CORS origins to allow your AWS IP
**Time**: ~1 minute

```bash
./5-update-cors.sh
```

### Helper Scripts

#### `helper-generate-token-key.sh`
**Run on**: Your local machine
**Purpose**: Generate secure 512-bit JWT token key

```bash
./helper-generate-token-key.sh
```

#### `helper-view-logs.sh`
**Run on**: AWS Lightsail instance
**Purpose**: View application, Nginx, or SQL Server logs

```bash
./helper-view-logs.sh
```

#### `helper-restart-services.sh`
**Run on**: AWS Lightsail instance
**Purpose**: Restart dating app, Nginx, or SQL Server

```bash
./helper-restart-services.sh
```

---

## ⚙️ Configuration Files

### `config/appsettings.Production.json`
Production application settings template.

**You must edit**:
- SQL Server SA password
- Cloudinary credentials (CloudName, ApiKey, ApiSecret)
- TokenKey (generate with `helper-generate-token-key.sh`)

### `config/dating-app.service`
Systemd service file for running the app as a service.

**Copy to server**:
```bash
scp -i ~/.ssh/key.pem config/dating-app.service ubuntu@IP:~/
sudo cp ~/dating-app.service /etc/systemd/system/
```

### `config/nginx-dating-app.conf`
Nginx reverse proxy configuration.

**Note**: The `4-setup-nginx.sh` script creates this automatically. This file is a reference template.

---

## 📋 Deployment Workflow

### Initial Deployment

```bash
# === LOCAL MACHINE ===
cd /home/user/DatingApp/deployment/scripts

# 1. Prepare configuration
./helper-generate-token-key.sh  # Save the output
./5-update-cors.sh               # Enter your AWS IP

# 2. Edit config with your values
nano ../config/appsettings.Production.json

# 3. Build application
./1-local-build.sh

# 4. Upload to server
scp -i ~/.ssh/key.pem 2-server-initial-setup.sh ubuntu@IP:~/
scp -i ~/.ssh/key.pem ../publish/dating-app-*.tar.gz ubuntu@IP:~/
scp -i ~/.ssh/key.pem ../config/appsettings.Production.json ubuntu@IP:~/
scp -i ~/.ssh/key.pem ../config/dating-app.service ubuntu@IP:~/
scp -i ~/.ssh/key.pem 3-deploy-app.sh ubuntu@IP:~/
scp -i ~/.ssh/key.pem 4-setup-nginx.sh ubuntu@IP:~/

# === SERVER ===
# SSH into server
ssh -i ~/.ssh/key.pem ubuntu@YOUR_IP

# 5. Initial server setup (once)
chmod +x ~/2-server-initial-setup.sh
./2-server-initial-setup.sh

# 6. Setup systemd service
sudo cp ~/dating-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dating-app

# 7. Deploy application
chmod +x ~/3-deploy-app.sh
./3-deploy-app.sh

# 8. Setup Nginx
chmod +x ~/4-setup-nginx.sh
./4-setup-nginx.sh
```

### Subsequent Updates

```bash
# === LOCAL MACHINE ===
# After making code changes
cd /home/user/DatingApp/deployment/scripts
./1-local-build.sh
scp -i ~/.ssh/key.pem ../publish/dating-app-*.tar.gz ubuntu@IP:~/

# === SERVER ===
./3-deploy-app.sh
```

---

## ✅ Post-Deployment Verification

### Check Services
```bash
sudo systemctl status dating-app
sudo systemctl status mssql-server
sudo systemctl status nginx
```

### Test Application
1. Open browser: `http://YOUR_STATIC_IP`
2. Register a new user
3. Login
4. Upload a photo (tests Cloudinary)
5. Send a message (tests SignalR)

### View Logs
```bash
# Application logs
sudo journalctl -u dating-app -f

# Nginx logs
sudo tail -f /var/log/nginx/dating-app-access.log
sudo tail -f /var/log/nginx/dating-app-error.log
```

---

## 🔧 Troubleshooting Quick Reference

| Problem | Check | Solution |
|---------|-------|----------|
| App won't start | `sudo journalctl -u dating-app -n 50` | Check configuration, SQL password |
| 502 Bad Gateway | `sudo systemctl status dating-app` | Restart app service |
| Can't connect to DB | `sudo systemctl status mssql-server` | Start SQL Server |
| CORS errors | Browser console | Update CORS origins in Program.cs |
| Upload fails | Cloudinary credentials | Verify appsettings.Production.json |

---

## 💰 Cost Breakdown

| Service | Monthly Cost |
|---------|-------------|
| AWS Lightsail (512MB, 1vCPU, 20GB) | $3.50 |
| Cloudinary (Free tier) | $0.00 |
| **Total** | **$3.50** |

---

## 🔐 Security Checklist

- [ ] Use strong SQL Server SA password
- [ ] Keep appsettings.Production.json secret (never commit to git)
- [ ] Restrict SSH key permissions: `chmod 400 key.pem`
- [ ] Enable firewall: `sudo ufw enable`
- [ ] Setup SSL/HTTPS with Let's Encrypt (optional but recommended)
- [ ] Regular system updates: `sudo apt update && sudo apt upgrade`

---

## 📞 Support

### Check the Guides First
1. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Comprehensive troubleshooting section
2. [QUICK_START.md](QUICK_START.md) - Quick commands reference

### Common Issues
- **Port already in use**: Check if another service is running on port 5000
- **Out of memory**: Consider adding swap file (guide in DEPLOYMENT_GUIDE.md)
- **Permission denied**: Ensure scripts are executable: `chmod +x script.sh`

---

## 🎯 What This Deployment Demonstrates

For your portfolio:

✅ **Cloud Skills**
- AWS Lightsail deployment
- Infrastructure setup
- Cost optimization

✅ **DevOps Knowledge**
- Linux server administration
- Systemd service management
- Nginx reverse proxy
- Automated deployments

✅ **Full-Stack Expertise**
- .NET Core backend
- Angular frontend
- SQL Server database
- Real-time features (SignalR)
- External API integration (Cloudinary)

✅ **Production Best Practices**
- Environment-specific configuration
- Proper logging
- Security headers
- Service monitoring

---

## 📝 License

This deployment package is part of Roy's .NET Dating App portfolio project.

---

## 🚀 Ready to Deploy?

1. **First time?** → Start with [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. **Need a refresher?** → Use [QUICK_START.md](QUICK_START.md)
3. **Ready to go?** → Run the scripts in order (1 → 2 → 3 → 4)

**Estimated Total Time**: 2-3 hours for first deployment

Good luck! 🎉

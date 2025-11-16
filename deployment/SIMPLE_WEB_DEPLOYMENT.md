# Simple AWS Deployment Guide (Web Browser Only!)

**No CLI required! Everything done through AWS web interface.**

**Cost**: $3.50/month | **Time**: 1 hour

---

## What You'll Need

Before starting:
- [ ] AWS Account (create at aws.amazon.com)
- [ ] Cloudinary account (free at cloudinary.com)
- [ ] These credentials ready:
  - Cloudinary Cloud Name
  - Cloudinary API Key
  - Cloudinary API Secret

---

## Part 1: Build Your App Locally (10 minutes)

### Option A: If you have .NET and Node.js installed

Open terminal on your computer:

```bash
# Navigate to project
cd /home/user/DatingApp

# Build Angular
cd client
npm install
npm run build

# Publish .NET app
cd ..
dotnet publish API/API.csproj -c Release -o ./publish

# Create zip file
cd publish
zip -r dating-app.zip .
```

Your `dating-app.zip` will be in the `publish` folder.

### Option B: If you don't have .NET/Node.js installed

**Skip building for now** - we'll set up the server first and build directly on it.

---

## Part 2: Create AWS Lightsail Instance (15 minutes)

### Step 1: Sign into AWS

1. Go to https://lightsail.aws.amazon.com/
2. Sign in (or create account)

### Step 2: Create Instance

1. Click the big orange **"Create instance"** button

2. **Instance location**: Choose region closest to you (default is fine)

3. **Pick your instance image**:
   - Click **"Linux/Unix"**
   - Click **"OS Only"**
   - Select **"Ubuntu 22.04 LTS"**

4. **Add launch script** (optional - makes setup easier!):

   Click **"+ Add launch script"** and paste this:

   ```bash
   #!/bin/bash
   # This runs automatically when instance is created

   # Update system
   apt-get update

   # Install .NET 9
   cd /home/ubuntu
   wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
   chmod +x dotnet-install.sh
   sudo -u ubuntu ./dotnet-install.sh --channel 9.0 --runtime aspnetcore --install-dir /home/ubuntu/.dotnet

   # Add to PATH
   echo 'export DOTNET_ROOT=$HOME/.dotnet' >> /home/ubuntu/.bashrc
   echo 'export PATH=$PATH:$HOME/.dotnet' >> /home/ubuntu/.bashrc

   # Install Nginx
   apt-get install -y nginx

   # Create app directory
   sudo -u ubuntu mkdir -p /home/ubuntu/dating-app
   ```

5. **Choose your instance plan**:
   - Select **"$3.50 USD"** (first option)
   - Shows: 512 MB, 1 vCPU, 20 GB SSD

6. **Name your instance**:
   - Enter: `dating-app`

7. Click **"Create instance"** (orange button at bottom)

8. **Wait 2-3 minutes** for instance to start (status will change to "Running")

### Step 3: Configure Networking

1. Click on your instance name **"dating-app"**

2. Click the **"Networking"** tab

3. Under **IPv4 Firewall**, click **"Add rule"** three times to add:

   | Application | Protocol | Port |
   |------------|----------|------|
   | Custom     | TCP      | 5000 |
   | HTTP       | TCP      | 80   |
   | HTTPS      | TCP      | 443  |

4. Under **IPv4 Public IP**, click **"Create static IP"**
   - Name: `dating-app-ip`
   - Click **"Create"**

5. **WRITE DOWN YOUR STATIC IP**: `___.___.___,___`

---

## Part 3: Install SQL Server (20 minutes)

### Step 1: Connect via Browser SSH

1. Go back to your instance (click "Instances" in top left, then click "dating-app")
2. Click the **"Connect using SSH"** button (looks like a terminal icon)
3. A browser window opens - this is your terminal!

### Step 2: One-Command SQL Server Setup

Copy and paste this entire block into the SSH terminal:

```bash
# Import Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add SQL Server repository
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" -y

# Install SQL Server
sudo apt-get update
sudo apt-get install -y mssql-server

# Install SQL Server tools
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
ACCEPT_EULA=Y sudo apt-get install -y mssql-tools unixodbc-dev

echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

Press Enter. Wait for it to complete (~5 minutes).

### Step 3: Configure SQL Server

Now run this command:

```bash
sudo /opt/mssql/bin/mssql-conf setup
```

When prompted:
1. Type **`2`** and press Enter (Express - free edition)
2. Type **`Yes`** and press Enter (accept license)
3. Enter a **strong password** (e.g., `MyApp2024!Secure`)
4. Re-enter the same password

**IMPORTANT: Write down this password!** `___________________`

SQL Server will start automatically.

---

## Part 4: Deploy Your Application (15 minutes)

### Step 1: Create Configuration File

In the SSH terminal, run:

```bash
nano ~/appsettings.Production.json
```

This opens a text editor. Paste this (replace the placeholders):

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
    "DefaultConnection": "Server=localhost;Database=DatingDB;User Id=SA;Password=YOUR_SQL_PASSWORD_HERE;TrustServerCertificate=True;Encrypt=False;"
  },
  "CloudinarySettings": {
    "CloudName": "YOUR_CLOUDINARY_CLOUD_NAME",
    "ApiKey": "YOUR_CLOUDINARY_API_KEY",
    "ApiSecret": "YOUR_CLOUDINARY_API_SECRET"
  },
  "TokenKey": "TEMP_KEY_REPLACE_LATER_WITH_REAL_KEY_FOR_SECURITY_PURPOSES_THIS_IS_JUST_A_PLACEHOLDER_STRING"
}
```

**Replace**:
- `YOUR_SQL_PASSWORD_HERE` - the SQL password you just created
- `YOUR_CLOUDINARY_CLOUD_NAME` - from Cloudinary dashboard
- `YOUR_CLOUDINARY_API_KEY` - from Cloudinary dashboard
- `YOUR_CLOUDINARY_API_SECRET` - from Cloudinary dashboard

**Save**: Press `Ctrl+X`, then `Y`, then `Enter`

### Step 2: Upload Your App

#### If you built the app locally (Option A):

On your **local computer**, open a new terminal and run:

```bash
# Navigate to where your zip file is
cd /home/user/DatingApp/publish

# Upload to server (replace YOUR_STATIC_IP)
scp -o "StrictHostKeyChecking=no" dating-app.zip ubuntu@YOUR_STATIC_IP:~/
```

If it asks for password, go back to Lightsail console:
- Click "Account" → "SSH Keys" → Download the key
- Then use: `scp -i /path/to/key.pem dating-app.zip ubuntu@YOUR_STATIC_IP:~/`

#### If you're building on the server (Option B):

In the SSH terminal:

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone your repo (or upload files another way)
# For now, we'll set up the structure
mkdir -p ~/dating-app
```

### Step 3: Extract and Setup App

In the SSH terminal:

```bash
# If you uploaded a zip file:
cd ~/dating-app
unzip ~/dating-app.zip

# Move configuration
mv ~/appsettings.Production.json ~/dating-app/

# Set permissions
chmod 600 ~/dating-app/appsettings.Production.json
```

### Step 4: Create Startup Service

Copy and paste this entire block:

```bash
sudo tee /etc/systemd/system/dating-app.service > /dev/null <<'EOF'
[Unit]
Description=Dating App .NET Service
After=network.target mssql-server.service

[Service]
WorkingDirectory=/home/ubuntu/dating-app
ExecStart=/home/ubuntu/.dotnet/dotnet /home/ubuntu/dating-app/API.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dating-app
User=ubuntu
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_ROOT=/home/ubuntu/.dotnet
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable dating-app
sudo systemctl start dating-app
```

### Step 5: Check if App Started

```bash
sudo systemctl status dating-app
```

You should see **"active (running)"** in green.

If you see errors, check logs:
```bash
sudo journalctl -u dating-app -n 50
```

---

## Part 5: Setup Nginx (10 minutes)

### Configure Nginx

Copy and paste this block (replace YOUR_STATIC_IP):

```bash
sudo tee /etc/nginx/sites-available/dating-app > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /hubs/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    client_max_body_size 10M;
}
EOF

# Enable site
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/dating-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Part 6: Test Your App! 🎉

1. Open your browser
2. Go to: `http://YOUR_STATIC_IP`
3. You should see your Dating App!

### Test Everything:
- [ ] Homepage loads
- [ ] Register new user
- [ ] Login
- [ ] Upload photo
- [ ] Send message

---

## Troubleshooting

### App won't load in browser?

Check if app is running:
```bash
sudo systemctl status dating-app
```

If not running, check logs:
```bash
sudo journalctl -u dating-app -n 100
```

### Database connection errors?

Check SQL Server:
```bash
sudo systemctl status mssql-server
```

If stopped, start it:
```bash
sudo systemctl start mssql-server
```

### Still having issues?

View all logs:
```bash
# App logs
sudo journalctl -u dating-app -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
```

---

## Maintenance Commands

### Restart the app
```bash
sudo systemctl restart dating-app
```

### View logs
```bash
sudo journalctl -u dating-app -f
```

### Update your app (after making changes)

1. Build new zip locally
2. Upload: `scp dating-app.zip ubuntu@YOUR_IP:~/`
3. On server:
```bash
sudo systemctl stop dating-app
cd ~/dating-app
rm -rf *
unzip ~/dating-app.zip
mv ~/appsettings.Production.json .
sudo systemctl start dating-app
```

---

## Making Updates Later

### To update your app:

1. **Build locally**:
   ```bash
   cd /home/user/DatingApp
   cd client && npm run build && cd ..
   dotnet publish API/API.csproj -c Release -o ./publish
   cd publish && zip -r dating-app.zip . && cd ..
   ```

2. **Upload**:
   ```bash
   scp publish/dating-app.zip ubuntu@YOUR_STATIC_IP:~/
   ```

3. **Deploy on server** (in SSH terminal):
   ```bash
   sudo systemctl stop dating-app
   cd ~/dating-app
   rm -rf * .[^.]*
   unzip ~/dating-app.zip
   cp ~/appsettings.Production.json .
   sudo systemctl start dating-app
   sudo systemctl status dating-app
   ```

---

## Cost Breakdown

- **AWS Lightsail**: $3.50/month
- **Cloudinary**: $0 (free tier)
- **Total**: $3.50/month ✅

---

## All Done!

Your app is now live at: `http://YOUR_STATIC_IP`

Add this to your portfolio and resume! You've successfully deployed a full-stack .NET + Angular application to AWS. 🚀

---

## Quick Command Reference

```bash
# Restart app
sudo systemctl restart dating-app

# View app logs (live)
sudo journalctl -u dating-app -f

# Check app status
sudo systemctl status dating-app

# Restart nginx
sudo systemctl restart nginx

# Restart SQL Server
sudo systemctl restart mssql-server

# Check server resources
htop
```

---

**Need help?** All commands can be copy-pasted directly into the browser SSH terminal. No downloads required!

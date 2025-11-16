# Ultra-Simple AWS Deployment (Copy-Paste Version)

**Minimal steps. Maximum simplicity. No CLI tools needed.**

**Time**: 45 minutes | **Cost**: $3.50/month

---

## Before You Start

### You Need:
1. AWS Account (sign up at aws.amazon.com)
2. Cloudinary account (free at cloudinary.com)
3. Your Cloudinary credentials:
   - Cloud Name: `_______________`
   - API Key: `_______________`
   - API Secret: `_______________`

---

## Step 1: Create AWS Server (5 minutes)

### Use AWS Web Interface:

1. Go to https://lightsail.aws.amazon.com/
2. Click **"Create instance"**
3. Choose:
   - Platform: **Linux/Unix**
   - Blueprint: **OS Only** → **Ubuntu 22.04 LTS**
   - Instance plan: **$3.50/month** (512 MB RAM)
   - Instance name: **`dating-app`**

4. Scroll down to **"+ Add launch script"**, click it, and paste:

```bash
#!/bin/bash
apt-get update
cd /home/ubuntu
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
sudo -u ubuntu ./dotnet-install.sh --channel 9.0 --runtime aspnetcore --install-dir /home/ubuntu/.dotnet
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> /home/ubuntu/.bashrc
echo 'export PATH=$PATH:$HOME/.dotnet' >> /home/ubuntu/.bashrc
apt-get install -y nginx
sudo -u ubuntu mkdir -p /home/ubuntu/dating-app
```

5. Click **"Create instance"** (orange button)

6. **Wait 3 minutes** for instance to start

### Setup Networking:

1. Click on your instance name **"dating-app"**
2. Click **"Networking"** tab
3. Click **"Add rule"** and add these:
   - Custom TCP **5000**
   - HTTP **80**
   - HTTPS **443**
4. Click **"Create static IP"**
   - Name: `dating-app-ip`
   - Click **"Create"**
5. **Write down your IP**: `___.___.___.___`

---

## Step 2: Setup Database (10 minutes)

1. Go to your instance page, click **"Connect using SSH"** (terminal icon)
2. Browser terminal opens
3. **Copy and paste this ENTIRE block** (one paste, press Enter):

```bash
# Install SQL Server
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" -y && \
sudo apt-get update && \
sudo apt-get install -y mssql-server && \
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list && \
sudo apt-get update && \
ACCEPT_EULA=Y sudo apt-get install -y mssql-tools unixodbc-dev && \
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc && \
source ~/.bashrc && \
echo "SQL Server installed! Now run: sudo /opt/mssql/bin/mssql-conf setup"
```

4. After it completes, run:

```bash
sudo /opt/mssql/bin/mssql-conf setup
```

5. When asked:
   - Edition: Type **`2`** (Express) and press Enter
   - License: Type **`Yes`** and press Enter
   - Password: Type a strong password (e.g., `MyApp2024!Strong`)
   - Confirm password: Type it again

**SAVE THIS PASSWORD**: `___________________`

---

## Step 3: Create Configuration (5 minutes)

Still in the SSH terminal, paste this:

```bash
cat > ~/config-template.json << 'CONFIGEND'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=DatingDB;User Id=SA;Password=SQL_PASSWORD_HERE;TrustServerCertificate=True;Encrypt=False;"
  },
  "CloudinarySettings": {
    "CloudName": "CLOUDINARY_CLOUD_NAME_HERE",
    "ApiKey": "CLOUDINARY_API_KEY_HERE",
    "ApiSecret": "CLOUDINARY_API_SECRET_HERE"
  },
  "TokenKey": "THIS_IS_A_TEMPORARY_PLACEHOLDER_TOKEN_KEY_REPLACE_WITH_A_REAL_SECURE_RANDOM_STRING_FOR_PRODUCTION_USE"
}
CONFIGEND

echo "Template created! Now edit it:"
```

Now edit the file:

```bash
nano ~/config-template.json
```

**Replace these values**:
- `SQL_PASSWORD_HERE` → your SQL password from Step 2
- `CLOUDINARY_CLOUD_NAME_HERE` → your Cloudinary cloud name
- `CLOUDINARY_API_KEY_HERE` → your Cloudinary API key
- `CLOUDINARY_API_SECRET_HERE` → your Cloudinary API secret

**Save**: Press `Ctrl+X`, then `Y`, then `Enter`

---

## Step 4: Build & Upload Your App (15 minutes)

### On Your Local Computer:

Open terminal and run:

```bash
cd /home/user/DatingApp

# Build Angular
cd client
npm install
npm run build

# Publish .NET
cd ..
dotnet publish API/API.csproj -c Release -o ./publish

# Create archive
cd publish
tar -czf dating-app.tar.gz *
echo "Package created at: $(pwd)/dating-app.tar.gz"
```

### Upload to Server:

Replace `YOUR_IP` with your static IP:

```bash
# Still in the publish directory
scp -o StrictHostKeyChecking=no dating-app.tar.gz ubuntu@YOUR_IP:~/
```

If it asks about fingerprint, type `yes`

If you need the SSH key:
- Go to Lightsail → Account → SSH Keys → Download
- Then use: `scp -i ~/Downloads/LightsailDefaultKey.pem dating-app.tar.gz ubuntu@YOUR_IP:~/`

---

## Step 5: Deploy Everything (10 minutes)

Back in the **SSH terminal** (browser), paste this ENTIRE block:

```bash
# Extract app
cd ~/dating-app
tar -xzf ~/dating-app.tar.gz

# Move config
cp ~/config-template.json ~/dating-app/appsettings.Production.json
chmod 600 ~/dating-app/appsettings.Production.json

# Create systemd service
sudo tee /etc/systemd/system/dating-app.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=Dating App Service
After=network.target mssql-server.service

[Service]
WorkingDirectory=/home/ubuntu/dating-app
ExecStart=/home/ubuntu/.dotnet/dotnet /home/ubuntu/dating-app/API.dll
Restart=always
RestartSec=10
User=ubuntu
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_ROOT=/home/ubuntu/.dotnet
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Configure Nginx
sudo tee /etc/nginx/sites-available/dating-app > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 10M;

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
}
NGINXEOF

# Enable everything
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/dating-app /etc/nginx/sites-enabled/
sudo systemctl daemon-reload
sudo systemctl enable dating-app
sudo systemctl start dating-app
sudo systemctl restart nginx

# Check status
echo ""
echo "========================================"
echo "Deployment Status:"
echo "========================================"
sudo systemctl status dating-app --no-pager | head -10
```

If you see **"active (running)"** in green, you're good! ✅

---

## Step 6: Test Your App! 🎉

Open browser and go to: **`http://YOUR_STATIC_IP`**

You should see your Dating App!

### Quick Test:
- [ ] Homepage loads
- [ ] Can register
- [ ] Can login
- [ ] Can upload photo

---

## Troubleshooting

### App not loading?

In SSH terminal:

```bash
# Check app status
sudo systemctl status dating-app

# View logs
sudo journalctl -u dating-app -n 50
```

### Database errors?

```bash
# Check SQL Server
sudo systemctl status mssql-server

# If not running, start it
sudo systemctl restart mssql-server
```

### Fix and restart:

```bash
# Restart everything
sudo systemctl restart mssql-server
sleep 5
sudo systemctl restart dating-app
sudo systemctl restart nginx

# Check status
sudo systemctl status dating-app
```

---

## Update Your App Later

When you make changes:

### 1. Build locally:
```bash
cd /home/user/DatingApp
cd client && npm run build && cd ..
dotnet publish API/API.csproj -c Release -o ./publish
cd publish && tar -czf dating-app.tar.gz * && cd ..
```

### 2. Upload:
```bash
scp publish/dating-app.tar.gz ubuntu@YOUR_IP:~/
```

### 3. Deploy (in SSH terminal):
```bash
sudo systemctl stop dating-app
cd ~/dating-app
rm -rf * .[^.]*
tar -xzf ~/dating-app.tar.gz
cp ~/config-template.json ./appsettings.Production.json
sudo systemctl start dating-app
```

---

## Useful Commands

```bash
# Restart app
sudo systemctl restart dating-app

# View logs (live)
sudo journalctl -u dating-app -f

# Check what's running
sudo systemctl status dating-app mssql-server nginx

# See resource usage
htop
```

---

## Summary

✅ **Total Time**: ~45 minutes
✅ **Monthly Cost**: $3.50
✅ **Your App**: `http://YOUR_STATIC_IP`

All done through the web browser - no complex CLI tools needed!

Add this to your portfolio! 🚀

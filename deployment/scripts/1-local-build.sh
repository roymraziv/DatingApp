#!/bin/bash
# ==============================================================================
# LOCAL BUILD AND PUBLISH SCRIPT
# ==============================================================================
# This script builds your Angular frontend and publishes the .NET backend
# Run this on your LOCAL machine before deploying to AWS
# ==============================================================================

set -e  # Exit on any error

echo "======================================"
echo "Dating App - Local Build Script"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo -e "${BLUE}Project Root: $PROJECT_ROOT${NC}"
echo ""

# Step 1: Build Angular Frontend
echo -e "${BLUE}[Step 1/4] Building Angular Frontend...${NC}"
cd "$PROJECT_ROOT/client"

if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
fi

echo "Building Angular app for production..."
npm run build

echo -e "${GREEN}✓ Angular build complete${NC}"
echo ""

# Step 2: Publish .NET Backend
echo -e "${BLUE}[Step 2/4] Publishing .NET Backend...${NC}"
cd "$PROJECT_ROOT"

# Clean previous publish
if [ -d "publish" ]; then
    echo "Cleaning previous publish directory..."
    rm -rf publish
fi

echo "Publishing .NET app..."
dotnet publish API/API.csproj -c Release -o ./publish

echo -e "${GREEN}✓ .NET publish complete${NC}"
echo ""

# Step 3: Create deployment package
echo -e "${BLUE}[Step 3/4] Creating deployment package...${NC}"
cd "$PROJECT_ROOT/publish"

# Create tarball
PACKAGE_NAME="dating-app-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$PACKAGE_NAME" *

echo -e "${GREEN}✓ Created package: $PACKAGE_NAME${NC}"
echo ""

# Step 4: Summary
echo -e "${BLUE}[Step 4/4] Build Summary${NC}"
echo "======================================"
echo "Package Location: $PROJECT_ROOT/publish/$PACKAGE_NAME"
PACKAGE_SIZE=$(du -h "$PROJECT_ROOT/publish/$PACKAGE_NAME" | cut -f1)
echo "Package Size: $PACKAGE_SIZE"
echo ""

echo -e "${GREEN}======================================"
echo "Build Complete!"
echo "======================================${NC}"
echo ""
echo "Next Steps:"
echo "1. Copy the deployment package to your AWS Lightsail instance:"
echo "   scp -i /path/to/LightsailDefaultKey.pem \\"
echo "       $PROJECT_ROOT/publish/$PACKAGE_NAME \\"
echo "       ubuntu@YOUR_STATIC_IP:~/"
echo ""
echo "2. Then run the deployment script on the server"
echo ""

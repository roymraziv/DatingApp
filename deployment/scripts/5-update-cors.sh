#!/bin/bash
# ==============================================================================
# UPDATE CORS ORIGINS SCRIPT
# ==============================================================================
# This script updates the CORS origins in Program.cs to match your deployment
# Run this on your LOCAL machine before building
# ==============================================================================

set -e

echo "======================================"
echo "Update CORS Origins"
echo "======================================"
echo ""

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
PROGRAM_CS="$PROJECT_ROOT/API/Program.cs"

# Check if Program.cs exists
if [ ! -f "$PROGRAM_CS" ]; then
    echo "Error: Program.cs not found at $PROGRAM_CS"
    exit 1
fi

echo "This script will update CORS origins in API/Program.cs"
echo ""
echo "Current CORS configuration:"
grep -A 1 "UseCors" "$PROGRAM_CS"
echo ""

# Get domain/IP
read -p "Enter your AWS Lightsail Static IP or domain: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "Error: Domain/IP cannot be empty"
    exit 1
fi

# Backup Program.cs
cp "$PROGRAM_CS" "$PROGRAM_CS.backup"
echo "Backed up Program.cs to Program.cs.backup"
echo ""

# Update CORS origins
echo "Updating CORS origins to allow:"
echo "  - http://$DOMAIN"
echo "  - https://$DOMAIN"
echo "  - http://localhost:4200 (for local development)"
echo ""

# Create new CORS configuration
NEW_CORS="app.UseCors(x => x.AllowAnyHeader().AllowAnyMethod().AllowCredentials()
    .WithOrigins(\"http://localhost:4200\", \"https://localhost:4200\", \"http://$DOMAIN\", \"https://$DOMAIN\"));"

# Replace in file (using sed for cross-platform compatibility)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "/app.UseCors/,/WithOrigins.*));/c\\
$NEW_CORS
" "$PROGRAM_CS"
else
    # Linux
    sed -i "/app.UseCors/,/WithOrigins.*));/c\\
$NEW_CORS
" "$PROGRAM_CS"
fi

echo "✓ CORS origins updated successfully"
echo ""
echo "New CORS configuration:"
grep -A 1 "UseCors" "$PROGRAM_CS"
echo ""
echo "Next step: Run the build script (1-local-build.sh)"
echo ""

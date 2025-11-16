#!/bin/bash
# ==============================================================================
# GENERATE TOKEN KEY
# ==============================================================================
# This script generates a secure random token key for JWT authentication
# ==============================================================================

echo "======================================"
echo "Generate JWT Token Key"
echo "======================================"
echo ""
echo "This will generate a secure 512-bit random key for JWT tokens."
echo ""

# Generate the token
TOKEN_KEY=$(openssl rand -base64 64 | tr -d '\n')

echo "Your generated TokenKey:"
echo ""
echo "----------------------------------------"
echo "$TOKEN_KEY"
echo "----------------------------------------"
echo ""
echo "Copy this value into your appsettings.Production.json file:"
echo "  \"TokenKey\": \"$TOKEN_KEY\""
echo ""
echo "IMPORTANT: Keep this key secret! Do not commit it to git."
echo ""

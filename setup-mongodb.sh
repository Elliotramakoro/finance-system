#!/bin/bash

# MpeoaERP MongoDB Setup Script for Render

echo "=== MpeoaERP MongoDB Setup ==="
echo ""

# Check if required environment variables are set
if [ -z "$MONGODB_URI" ]; then
    echo "ERROR: MONGODB_URI environment variable is not set"
    echo "Please set it before running this script"
    exit 1
fi

if [ -z "$MONGODB_DATABASE" ]; then
    echo "ERROR: MONGODB_DATABASE environment variable is not set"
    echo "Default: mpeoa_erp"
    export MONGODB_DATABASE="mpeoa_erp"
fi

echo "MongoDB URI: ${MONGODB_URI%*@*}@****"
echo "Database: $MONGODB_DATABASE"
echo ""

# This script will be called during application startup
# The DatabaseUtil class will automatically create indexes and verify collections

echo "✓ MongoDB environment variables configured"
echo "✓ Application will initialize database on startup"
echo ""

# Optional: Run Java initialization if needed
# java -cp ".:classes/*" com.mpeoa.utils.MongoDBInitializer

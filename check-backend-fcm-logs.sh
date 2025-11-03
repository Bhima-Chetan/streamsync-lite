#!/bin/bash

# Script to check backend logs on EC2 for FCM token registration errors

echo "🔍 Checking backend logs for FCM token registration..."
echo ""

# Check PM2 logs for the last 100 lines
pm2 logs streamsync-backend --lines 100 --nostream | grep -i "fcm\|token\|register" || echo "No FCM-related logs found"

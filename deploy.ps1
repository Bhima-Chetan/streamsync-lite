# StreamSync Lite - AWS Deployment Script (PowerShell)
# Usage: .\deploy.ps1 -EC2IP "your-ip" -KeyFile "path\to\key.pem" [-RDSEndpoint "rds-endpoint"]

param(
    [Parameter(Mandatory=$true)]
    [string]$EC2IP,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyFile,
    
    [Parameter(Mandatory=$false)]
    [string]$RDSEndpoint = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$RemoteUser = "ec2-user"
$AppName = "streamsync-api"
$RepoUrl = "https://github.com/Bhima-Chetan/streamsync-lite.git"

Write-Host "🚀 StreamSync Lite Deployment Script (PM2 + NGINX)" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green

# Check if key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "❌ Error: Key file not found: $KeyFile" -ForegroundColor Red
    exit 1
}

# Prompt for RDS endpoint if not provided
if ([string]::IsNullOrEmpty($RDSEndpoint)) {
    $RDSEndpoint = Read-Host "Enter your RDS endpoint (e.g., streamsync-db.xxxxx.us-east-1.rds.amazonaws.com)"
}

Write-Host "� Configuration:" -ForegroundColor Cyan
Write-Host "  EC2 IP: $EC2IP" -ForegroundColor White
Write-Host "  RDS Endpoint: $RDSEndpoint" -ForegroundColor White
Write-Host ""

Write-Host "🔧 Deploying on EC2..." -ForegroundColor Yellow

$deployCommands = @"
set -e

echo '📥 Cloning/Updating repository...'
if [ -d "streamsync-lite" ]; then
    cd streamsync-lite
    git pull origin main
else
    git clone $RepoUrl
    cd streamsync-lite
fi

cd backend

echo '📦 Installing dependencies...'
npm ci --only=production

echo '� Building application...'
npm run build

echo '🔑 Creating environment loader script...'
cat > load-env.sh << 'ENVEOF'
#!/bin/bash
export NODE_ENV=production
export PORT=3000
export DATABASE_HOST=$RDSEndpoint
export DATABASE_PORT=5432
export DATABASE_USER=postgres
export DATABASE_NAME=streamsync
export JWT_EXPIRES_IN=24h
export JWT_REFRESH_EXPIRES_IN=7d
export FIREBASE_PROJECT_ID=streamsync-dccc1
export FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@streamsync-dccc1.iam.gserviceaccount.com
export RATE_LIMIT_TTL=60
export RATE_LIMIT_MAX=100

# Fetch secrets from Parameter Store
export DATABASE_PASSWORD=`$(aws ssm get-parameter --name "/streamsync/production/DATABASE_PASSWORD" --with-decryption --query "Parameter.Value" --output text --region us-east-1 2>/dev/null || echo "")
export JWT_SECRET=`$(aws ssm get-parameter --name "/streamsync/production/JWT_SECRET" --with-decryption --query "Parameter.Value" --output text --region us-east-1 2>/dev/null || echo "")
export JWT_REFRESH_SECRET=`$(aws ssm get-parameter --name "/streamsync/production/JWT_REFRESH_SECRET" --with-decryption --query "Parameter.Value" --output text --region us-east-1 2>/dev/null || echo "")
export FIREBASE_PRIVATE_KEY=`$(aws ssm get-parameter --name "/streamsync/production/FIREBASE_PRIVATE_KEY" --with-decryption --query "Parameter.Value" --output text --region us-east-1 2>/dev/null || echo "")
export YOUTUBE_API_KEY=`$(aws ssm get-parameter --name "/streamsync/production/YOUTUBE_API_KEY" --with-decryption --query "Parameter.Value" --output text --region us-east-1 2>/dev/null || echo "AIzaSyAo9PdNWl5fPr57VhRVZWJu8rmTAh8Noo4")
ENVEOF

chmod +x load-env.sh

echo '🚀 Starting/Restarting with PM2...'
source ./load-env.sh

# Check if PM2 process exists
if pm2 describe streamsync-api > /dev/null 2>&1; then
    echo '🔄 Restarting existing PM2 process...'
    pm2 restart streamsync-api --update-env
else
    echo '▶️ Starting new PM2 process...'
    pm2 start dist/main.js --name streamsync-api
    pm2 save
fi

echo '⏳ Waiting for application to start...'
sleep 3

echo '📊 PM2 Status:'
pm2 status

echo ''
echo '📋 Application logs (last 30 lines):'
pm2 logs streamsync-api --lines 30 --nostream

echo ''
echo '🌐 Testing health endpoint...'
sleep 2
curl -f http://localhost:3000/health && echo '✅ Health check passed!' || echo '❌ Health check failed!'

echo ''
echo '✅ Deployment complete!'
echo '🌐 API URL: http://`$(curl -s ifconfig.me)'
echo '📖 API Docs: http://`$(curl -s ifconfig.me)/api/docs'
echo '🏥 Health: http://`$(curl -s ifconfig.me)/health'
echo ''
echo '📝 Useful commands:'
echo '  pm2 logs streamsync-api    # View logs'
echo '  pm2 restart streamsync-api # Restart app'
echo '  pm2 monit                  # Monitor resources'
echo '  sudo systemctl status nginx # Check NGINX'
"@

ssh -i $KeyFile -o StrictHostKeyChecking=no "${RemoteUser}@${EC2IP}" $deployCommands

Write-Host ""
Write-Host "✅ Deployment successful!" -ForegroundColor Green
Write-Host "🌐 Your API is now running at: http://${EC2IP}" -ForegroundColor Green
Write-Host "📖 API Documentation: http://${EC2IP}/api/docs" -ForegroundColor Green
Write-Host "🏥 Health Check: http://${EC2IP}/health" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Next steps:" -ForegroundColor Yellow
Write-Host "1. Update Flutter app API base URL in api_client.dart:"
Write-Host "   static const String baseUrl = 'http://${EC2IP}';" -ForegroundColor Cyan
Write-Host "2. Verify NGINX is proxying correctly:"
Write-Host "   curl http://${EC2IP}/health" -ForegroundColor Cyan
Write-Host "3. Check CloudWatch logs in AWS Console"
Write-Host "4. (Optional) Set up domain with Route 53 and SSL"
Write-Host ""
Write-Host "📝 To view logs:" -ForegroundColor Yellow
Write-Host "ssh -i $KeyFile ${RemoteUser}@${EC2IP} 'pm2 logs streamsync-api'" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 To manage PM2:" -ForegroundColor Yellow
Write-Host "ssh -i $KeyFile ${RemoteUser}@${EC2IP}" -ForegroundColor Cyan
Write-Host "Then run: pm2 status | pm2 restart streamsync-api | pm2 monit"

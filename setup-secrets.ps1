# AWS Systems Manager Parameter Store Setup Script
# Usage: .\setup-secrets.ps1 -Region "us-east-1"

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 StreamSync AWS Parameter Store Setup" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
} catch {
    Write-Host "❌ Error: AWS CLI is not installed" -ForegroundColor Red
    Write-Host "Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✅ AWS credentials configured" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "This script will store your secrets in AWS Systems Manager Parameter Store." -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor White
Write-Host ""

# Function to create parameter
function Set-SecureParameter {
    param(
        [string]$Name,
        [string]$Description,
        [string]$DefaultValue = ""
    )
    
    Write-Host "📝 $Description" -ForegroundColor Yellow
    
    # Check if parameter already exists
    $exists = $false
    try {
        aws ssm get-parameter --name $Name --region $Region 2>$null | Out-Null
        $exists = $true
    } catch {}
    
    if ($exists) {
        $overwrite = Read-Host "  Parameter already exists. Overwrite? (y/N)"
        if ($overwrite -ne "y") {
            Write-Host "  ⏭️ Skipped" -ForegroundColor Gray
            return
        }
    }
    
    if ([string]::IsNullOrEmpty($DefaultValue)) {
        $value = Read-Host "  Enter value" -AsSecureString
        $value = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
        )
    } else {
        $useDefault = Read-Host "  Use default value? (Y/n)"
        if ($useDefault -eq "n") {
            $value = Read-Host "  Enter value" -AsSecureString
            $value = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
            )
        } else {
            $value = $DefaultValue
        }
    }
    
    if ($exists) {
        aws ssm put-parameter `
            --name $Name `
            --value $value `
            --type "SecureString" `
            --overwrite `
            --region $Region | Out-Null
    } else {
        aws ssm put-parameter `
            --name $Name `
            --value $value `
            --type "SecureString" `
            --region $Region | Out-Null
    }
    
    Write-Host "  ✅ Stored successfully" -ForegroundColor Green
}

# Store secrets
Write-Host "Setting up secrets for /streamsync/production..." -ForegroundColor Cyan
Write-Host ""

Set-SecureParameter `
    -Name "/streamsync/production/DATABASE_PASSWORD" `
    -Description "RDS PostgreSQL password"

Set-SecureParameter `
    -Name "/streamsync/production/JWT_SECRET" `
    -Description "JWT secret (generate random string)"

Set-SecureParameter `
    -Name "/streamsync/production/JWT_REFRESH_SECRET" `
    -Description "JWT refresh secret (generate random string)"

# Read Firebase private key from local .env
$firebaseKey = ""
if (Test-Path "backend\.env") {
    $envContent = Get-Content "backend\.env" -Raw
    if ($envContent -match 'FIREBASE_PRIVATE_KEY="([^"]+)"') {
        $firebaseKey = $Matches[1]
    }
}

if ([string]::IsNullOrEmpty($firebaseKey)) {
    Write-Host ""
    Write-Host "📝 Firebase Private Key" -ForegroundColor Yellow
    Write-Host "  Paste your Firebase private key (including -----BEGIN PRIVATE KEY-----)" -ForegroundColor Cyan
    Write-Host "  Press Enter twice when done:" -ForegroundColor Cyan
    $lines = @()
    while ($true) {
        $line = Read-Host
        if ([string]::IsNullOrEmpty($line)) { break }
        $lines += $line
    }
    $firebaseKey = $lines -join "\n"
} else {
    Write-Host ""
    Write-Host "📝 Firebase Private Key" -ForegroundColor Yellow
    Write-Host "  Found in backend\.env" -ForegroundColor Green
}

aws ssm put-parameter `
    --name "/streamsync/production/FIREBASE_PRIVATE_KEY" `
    --value $firebaseKey `
    --type "SecureString" `
    --overwrite `
    --region $Region | Out-Null

Write-Host "  ✅ Stored successfully" -ForegroundColor Green

Set-SecureParameter `
    -Name "/streamsync/production/YOUTUBE_API_KEY" `
    -Description "YouTube Data API Key" `
    -DefaultValue "AIzaSyAo9PdNWl5fPr57VhRVZWJu8rmTAh8Noo4"

Write-Host ""
Write-Host "✅ All secrets stored in AWS Parameter Store!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Created parameters:" -ForegroundColor Cyan
aws ssm describe-parameters --region $Region --query "Parameters[?Name.contains(@, '/streamsync/production/')].[Name]" --output table

Write-Host ""
Write-Host "🔑 Next steps:" -ForegroundColor Yellow
Write-Host "1. Attach IAM role to EC2 instance with AmazonSSMReadOnlyAccess policy"
Write-Host "2. Deploy application using: .\deploy.ps1 -EC2IP 'your-ip' -KeyFile 'your-key.pem'"
Write-Host ""
Write-Host "💡 To view a parameter:" -ForegroundColor Yellow
Write-Host "aws ssm get-parameter --name '/streamsync/production/DATABASE_PASSWORD' --with-decryption --region $Region" -ForegroundColor Cyan

#!/usr/bin/env pwsh
# StreamSync Lite - Automated Setup Script for Windows PowerShell

Write-Host "StreamSync Lite - Automated Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$ROOT_DIR = "c:\STREAMSYNC"

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js not found. Please install Node.js 18+" -ForegroundColor Red
    exit 1
}

# Check Flutter
try {
    $flutterCheck = flutter --version 2>&1 | Out-Null
    Write-Host "[OK] Flutter: Installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Flutter not found. Please install Flutter SDK" -ForegroundColor Red
    exit 1
}

# Check PostgreSQL
$postgresRunning = Get-Process postgres -ErrorAction SilentlyContinue
if ($postgresRunning) {
    Write-Host "[OK] PostgreSQL: Running" -ForegroundColor Green
} else {
    Write-Host "[WARN] PostgreSQL: Not detected. You'll need to start it manually" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setting up Backend..." -ForegroundColor Yellow
Set-Location "$ROOT_DIR\backend"

if (!(Test-Path "node_modules")) {
    Write-Host "Installing npm packages..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Backend dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to install backend dependencies" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[OK] Backend dependencies already installed" -ForegroundColor Green
}

if (!(Test-Path ".env")) {
    Write-Host "Creating .env file from template..." -ForegroundColor Gray
    Copy-Item ".env.example" ".env"
    Write-Host "[WARN] Please edit .env and add your API keys" -ForegroundColor Yellow
} else {
    Write-Host "[OK] .env file exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Setting up Frontend..." -ForegroundColor Yellow
Set-Location "$ROOT_DIR\frontend"

Write-Host "Getting Flutter dependencies..." -ForegroundColor Gray
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Flutter dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to get Flutter dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "Generating code..." -ForegroundColor Gray
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Code generation complete" -ForegroundColor Green
} else {
    Write-Host "[WARN] Code generation had warnings (this is normal)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Edit backend\.env with your API keys (YouTube, Firebase, Database)" -ForegroundColor White
Write-Host "2. Start PostgreSQL if not running" -ForegroundColor White
Write-Host "3. Run backend: cd backend && npm run start:dev" -ForegroundColor White
Write-Host "4. Run worker: cd backend && npm run start:worker (in new terminal)" -ForegroundColor White
Write-Host "5. Configure Firebase: Add google-services.json to frontend\android\app\" -ForegroundColor White
Write-Host "6. Run app: cd frontend && flutter run" -ForegroundColor White
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "   - README.md - Project overview" -ForegroundColor White
Write-Host "   - IMPLEMENTATION_GUIDE.md - Detailed implementation steps" -ForegroundColor White
Write-Host "   - QUICK_START.md - Quick reference commands" -ForegroundColor White
Write-Host ""
Write-Host "Ready to code! Good luck with your hackathon!" -ForegroundColor Green

Set-Location $ROOT_DIR

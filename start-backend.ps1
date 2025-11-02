# Start Backend Server Script

Write-Host "Starting StreamSync Backend Server..." -ForegroundColor Green

# Change to backend directory
Set-Location C:\STREAMSYNC\backend

# Check if node_modules exists
if (!(Test-Path "node_modules")) {
    Write-Host "[WARN] node_modules not found. Running npm install..." -ForegroundColor Yellow
    npm install
}

# Check if .env exists
if (!(Test-Path ".env")) {
    Write-Host "[ERROR] .env file not found! Please create it first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Backend server starting on http://localhost:3000" -ForegroundColor Cyan
Write-Host "API Documentation: http://localhost:3000/api/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] Note: PostgreSQL must be running for full functionality" -ForegroundColor Yellow
Write-Host "[INFO] Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the development server
npm run start:dev

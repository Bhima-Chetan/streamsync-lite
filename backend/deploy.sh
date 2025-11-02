#!/bin/bash

# ==========================================
# StreamSync Backend Deployment Script
# ==========================================
# This script automates the deployment process
# on AWS EC2 instance
# ==========================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/var/www/streamsync/backend"
LOG_DIR="/var/log/streamsync"
BACKUP_DIR="/var/backups/streamsync"
GIT_BRANCH="${GIT_BRANCH:-main}"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as correct user
check_user() {
    if [ "$EUID" -eq 0 ]; then 
        log_error "Please do not run this script as root"
        exit 1
    fi
}

# Create backup
create_backup() {
    log_info "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    cd "$APP_DIR/.."
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" backend/ || {
        log_warning "Backup failed, but continuing deployment"
    }
    
    # Keep only last 5 backups
    cd "$BACKUP_DIR"
    ls -t | tail -n +6 | xargs -r rm --
    
    log_success "Backup created: $BACKUP_NAME"
}

# Pull latest code
pull_code() {
    log_info "Pulling latest code from Git..."
    
    cd "$APP_DIR/.."
    git fetch origin
    git checkout "$GIT_BRANCH"
    git pull origin "$GIT_BRANCH"
    
    log_success "Code updated successfully"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    cd "$APP_DIR"
    npm ci --production
    
    log_success "Dependencies installed"
}

# Build application
build_app() {
    log_info "Building application..."
    
    cd "$APP_DIR"
    npm run build
    
    log_success "Build completed"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    cd "$APP_DIR"
    npm run typeorm:migration:run || {
        log_warning "Migration failed or no pending migrations"
    }
    
    log_success "Migrations completed"
}

# Reload PM2 processes
reload_pm2() {
    log_info "Reloading PM2 processes..."
    
    pm2 reload ecosystem.config.js
    
    log_success "PM2 processes reloaded"
}

# Health check
health_check() {
    log_info "Running health check..."
    
    sleep 5  # Wait for app to start
    
    HEALTH_URL="http://localhost:3000/health"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")
    
    if [ "$RESPONSE" = "200" ]; then
        log_success "Health check passed (HTTP $RESPONSE)"
    else
        log_error "Health check failed (HTTP $RESPONSE)"
        log_error "Rolling back..."
        rollback
        exit 1
    fi
}

# Rollback
rollback() {
    log_warning "Rolling back to previous version..."
    
    cd "$APP_DIR/.."
    git reset --hard HEAD~1
    
    cd "$APP_DIR"
    npm ci --production
    npm run build
    
    pm2 reload ecosystem.config.js
    
    log_warning "Rollback completed"
}

# Show status
show_status() {
    log_info "Checking application status..."
    echo ""
    pm2 status
    echo ""
    pm2 logs --lines 20
}

# Main deployment flow
main() {
    echo ""
    log_info "=========================================="
    log_info "  StreamSync Deployment Script"
    log_info "=========================================="
    echo ""
    
    check_user
    create_backup
    pull_code
    install_dependencies
    build_app
    run_migrations
    reload_pm2
    health_check
    
    echo ""
    log_success "=========================================="
    log_success "  Deployment Completed Successfully!"
    log_success "=========================================="
    echo ""
    
    show_status
}

# Run main function
main "$@"

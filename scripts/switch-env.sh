#!/bin/bash

# OneAlarm Environment Switcher
# Usage: ./scripts/switch-env.sh [development|production]

set -e

# Source the config
source "$(dirname "$0")/config.sh"

# Function to show usage
show_usage() {
    echo "Usage: $0 [development|production]"
    echo ""
    echo "Switches the current environment configuration."
    echo ""
    echo "Examples:"
    echo "  $0 development    # Switch to development environment"
    echo "  $0 production     # Switch to production environment"
    echo ""
    echo "Current environment: $ENVIRONMENT"
}

# Function to switch environment
switch_environment() {
    local target_env="$1"
    local env_file="env.$target_env"
    
    if [ ! -f "$env_file" ]; then
        log_error "Environment file not found: $env_file"
        exit 1
    fi
    
    log_info "Switching to $target_env environment..."
    
    # Backup current .env if it exists
    if [ -f ".env" ]; then
        cp .env .env.backup
        log_info "Backed up current .env to .env.backup"
    fi
    
    # Copy the target environment file to .env
    cp "$env_file" .env
    log_success "Switched to $target_env environment"
    
    # Show the new environment info
    echo ""
    show_environment_info
    echo ""
    log_info "You may need to update API keys in .env file"
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    "development"|"dev")
        switch_environment "development"
        ;;
    "production"|"prod")
        switch_environment "production"
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        log_error "Invalid environment: $1"
        show_usage
        exit 1
        ;;
esac 
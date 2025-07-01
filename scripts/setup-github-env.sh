#!/bin/bash

# OneAlarm GitHub Environment Setup Script
# This script helps set up GitHub environments and secrets for CI/CD

set -e

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first:"
        echo "  macOS: brew install gh"
        echo "  Ubuntu: sudo apt install gh"
        echo "  Windows: winget install GitHub.cli"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run: gh auth login"
        exit 1
    fi
    
    print_success "GitHub CLI is installed and authenticated"
}

# Function to get repository information
get_repo_info() {
    print_status "Getting repository information..."
    
    # Get current repository
    REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [ -z "$REPO_URL" ]; then
        print_error "No Git repository found. Please initialize Git and add a remote origin."
        exit 1
    fi
    
    # Extract owner and repo name
    if [[ $REPO_URL == *"github.com"* ]]; then
        REPO_FULL_NAME=$(echo "$REPO_URL" | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\)\.git.*/\1/')
        REPO_OWNER=$(echo "$REPO_FULL_NAME" | cut -d'/' -f1)
        REPO_NAME=$(echo "$REPO_FULL_NAME" | cut -d'/' -f2)
    else
        print_error "Repository URL does not appear to be a GitHub repository"
        exit 1
    fi
    
    print_success "Repository: $REPO_FULL_NAME"
}

# Function to create GitHub environments
create_environments() {
    print_status "Creating GitHub environments..."
    
    # Create development environment
    if ! gh api repos/$REPO_FULL_NAME/environments/development &> /dev/null; then
        print_status "Creating development environment..."
        gh api repos/$REPO_FULL_NAME/environments \
            --method POST \
            --field name=development \
            --field protection_rules='[{"required_reviewers":{"type":"User","reviewers":["'$REPO_OWNER'"]}}]' \
            --silent
        print_success "Development environment created"
    else
        print_success "Development environment already exists"
    fi
    
    # Create production environment
    if ! gh api repos/$REPO_FULL_NAME/environments/production &> /dev/null; then
        print_status "Creating production environment..."
        gh api repos/$REPO_FULL_NAME/environments \
            --method POST \
            --field name=production \
            --field protection_rules='[{"required_reviewers":{"type":"User","reviewers":["'$REPO_OWNER'"]}}]' \
            --silent
        print_success "Production environment created"
    else
        print_success "Production environment already exists"
    fi
}

# Function to prompt for environment variables
prompt_for_env_vars() {
    print_status "Setting up environment variables..."
    
    echo
    print_warning "You will need to provide the following environment variables:"
    echo
    echo "Development Environment:"
    echo "  - SUPABASE_URL_DEV"
    echo "  - SUPABASE_SERVICE_ROLE_KEY_DEV"
    echo "  - SUPABASE_DEV_PROJECT_REF"
    echo "  - OPENAI_API_KEY_DEV"
    echo "  - NEWSAPI_KEY_DEV"
    echo "  - SPORTSDB_API_KEY_DEV"
    echo "  - RAPIDAPI_KEY_DEV"
    echo "  - ABSTRACT_API_KEY_DEV"
    echo
    echo "Production Environment:"
    echo "  - SUPABASE_URL_PROD"
    echo "  - SUPABASE_SERVICE_ROLE_KEY_PROD"
    echo "  - SUPABASE_PROD_PROJECT_REF"
    echo "  - OPENAI_API_KEY_PROD"
    echo "  - NEWSAPI_KEY_PROD"
    echo "  - SPORTSDB_API_KEY_PROD"
    echo "  - RAPIDAPI_KEY_PROD"
    echo "  - ABSTRACT_API_KEY_PROD"
    echo
    
    read -p "Do you want to set these up now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_environment_variables
    else
        print_warning "You can set these up later using the GitHub web interface or gh CLI"
        print_status "Repository Settings > Environments > [Environment Name] > Environment secrets"
    fi
}

# Function to set environment variables
set_environment_vars() {
    print_status "Setting environment variables..."
    
    # Development environment
    print_status "Setting up development environment variables..."
    
    read -p "SUPABASE_URL_DEV: " SUPABASE_URL_DEV
    read -p "SUPABASE_SERVICE_ROLE_KEY_DEV: " SUPABASE_SERVICE_ROLE_KEY_DEV
    read -p "SUPABASE_DEV_PROJECT_REF: " SUPABASE_DEV_PROJECT_REF
    read -p "OPENAI_API_KEY_DEV: " OPENAI_API_KEY_DEV
    read -p "NEWSAPI_KEY_DEV: " NEWSAPI_KEY_DEV
    read -p "SPORTSDB_API_KEY_DEV: " SPORTSDB_API_KEY_DEV
    read -p "RAPIDAPI_KEY_DEV: " RAPIDAPI_KEY_DEV
    read -p "ABSTRACT_API_KEY_DEV: " ABSTRACT_API_KEY_DEV
    
    # Set development secrets
    gh secret set SUPABASE_URL_DEV --body "$SUPABASE_URL_DEV" --env development
    gh secret set SUPABASE_SERVICE_ROLE_KEY_DEV --body "$SUPABASE_SERVICE_ROLE_KEY_DEV" --env development
    gh secret set SUPABASE_DEV_PROJECT_REF --body "$SUPABASE_DEV_PROJECT_REF" --env development
    gh secret set OPENAI_API_KEY_DEV --body "$OPENAI_API_KEY_DEV" --env development
    gh secret set NEWSAPI_KEY_DEV --body "$NEWSAPI_KEY_DEV" --env development
    gh secret set SPORTSDB_API_KEY_DEV --body "$SPORTSDB_API_KEY_DEV" --env development
    gh secret set RAPIDAPI_KEY_DEV --body "$RAPIDAPI_KEY_DEV" --env development
    gh secret set ABSTRACT_API_KEY_DEV --body "$ABSTRACT_API_KEY_DEV" --env development
    
    print_success "Development environment variables set"
    
    # Production environment
    print_status "Setting up production environment variables..."
    
    read -p "SUPABASE_URL_PROD: " SUPABASE_URL_PROD
    read -p "SUPABASE_SERVICE_ROLE_KEY_PROD: " SUPABASE_SERVICE_ROLE_KEY_PROD
    read -p "SUPABASE_PROD_PROJECT_REF: " SUPABASE_PROD_PROJECT_REF
    read -p "OPENAI_API_KEY_PROD: " OPENAI_API_KEY_PROD
    read -p "NEWSAPI_KEY_PROD: " NEWSAPI_KEY_PROD
    read -p "SPORTSDB_API_KEY_PROD: " SPORTSDB_API_KEY_PROD
    read -p "RAPIDAPI_KEY_PROD: " RAPIDAPI_KEY_PROD
    read -p "ABSTRACT_API_KEY_PROD: " ABSTRACT_API_KEY_PROD
    
    # Set production secrets
    gh secret set SUPABASE_URL_PROD --body "$SUPABASE_URL_PROD" --env production
    gh secret set SUPABASE_SERVICE_ROLE_KEY_PROD --body "$SUPABASE_SERVICE_ROLE_KEY_PROD" --env production
    gh secret set SUPABASE_PROD_PROJECT_REF --body "$SUPABASE_PROD_PROJECT_REF" --env production
    gh secret set OPENAI_API_KEY_PROD --body "$OPENAI_API_KEY_PROD" --env production
    gh secret set NEWSAPI_KEY_PROD --body "$NEWSAPI_KEY_PROD" --env production
    gh secret set SPORTSDB_API_KEY_PROD --body "$SPORTSDB_API_KEY_PROD" --env production
    gh secret set RAPIDAPI_KEY_PROD --body "$RAPIDAPI_KEY_PROD" --env production
    gh secret set ABSTRACT_API_KEY_PROD --body "$ABSTRACT_API_KEY_PROD" --env production
    
    print_success "Production environment variables set"
}

# Function to create initial commit
create_initial_commit() {
    print_status "Creating initial commit..."
    
    if [ -z "$(git status --porcelain)" ]; then
        print_success "No changes to commit"
        return
    fi
    
    git add .
    git commit -m "feat: Initial CI/CD setup

- Add GitHub Actions workflows for CI, deployment, and cron jobs
- Add issue and PR templates
- Add CODEOWNERS and Dependabot configuration
- Standardize environment configuration
- Remove hardcoded URLs from scripts"
    
    print_success "Initial commit created"
}

# Function to push to GitHub
push_to_github() {
    print_status "Pushing to GitHub..."
    
    # Check if remote exists
    if ! git remote get-url origin &> /dev/null; then
        print_error "No remote origin found. Please add your GitHub repository as origin."
        exit 1
    fi
    
    # Push to main branch
    git push -u origin main
    
    print_success "Code pushed to GitHub"
}

# Function to enable GitHub Actions
enable_actions() {
    print_status "Enabling GitHub Actions..."
    
    # Enable Actions for the repository
    gh api repos/$REPO_FULL_NAME/actions/permissions \
        --method PUT \
        --field enabled=true \
        --field allowed_actions=all \
        --silent
    
    print_success "GitHub Actions enabled"
}

# Main execution
main() {
    echo "🚀 OneAlarm GitHub Environment Setup"
    echo "====================================="
    echo
    
    # Check prerequisites
    check_gh_cli
    get_repo_info
    
    # Create environments
    create_environments
    
    # Prompt for environment variables
    prompt_for_env_vars
    
    # Create initial commit
    create_initial_commit
    
    # Push to GitHub
    push_to_github
    
    # Enable Actions
    enable_actions
    
    echo
    print_success "GitHub environment setup completed!"
    echo
    print_status "Next steps:"
    echo "1. Verify environments are created in GitHub repository settings"
    echo "2. Set up environment variables if not done already"
    echo "3. Test the CI workflow by making a small change"
    echo "4. Review and approve the first deployment"
    echo
    print_status "Repository URL: https://github.com/$REPO_FULL_NAME"
    print_status "Actions URL: https://github.com/$REPO_FULL_NAME/actions"
}

# Run main function
main "$@" 
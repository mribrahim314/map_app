#!/bin/bash

# Database Migration Runner
# This script applies all pending migrations to the database

set -e  # Exit on error

# Default database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-map_app}"
DB_USER="${DB_USER:-postgres}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "Database Migration Runner"
echo "============================================"
echo ""
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "User: $DB_USER"
echo ""

# Function to check if database exists
check_database() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"
}

# Function to run SQL file
run_migration() {
    local file=$1
    local description=$2

    echo -e "${YELLOW}Running: $description${NC}"
    echo "File: $file"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        exit 1
    fi

    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file"; then
        echo -e "${GREEN}✓ Successfully applied: $description${NC}"
        echo ""
    else
        echo -e "${RED}✗ Failed to apply: $description${NC}"
        exit 1
    fi
}

# Check if database exists
if ! check_database; then
    echo -e "${YELLOW}Database '$DB_NAME' does not exist. Creating...${NC}"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"
    echo -e "${GREEN}✓ Database created${NC}"
    echo ""
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Run migrations in order
echo "============================================"
echo "Applying Migrations"
echo "============================================"
echo ""

# Migration 1: Base schema
run_migration "schema.sql" "Base schema with PostGIS support"

# Migration 2: Align schema with backend API
run_migration "migration_001_align_schema.sql" "Align schema with backend API"

# Migration 3: Fix users ID generation
run_migration "migration_002_fix_users_id_generation.sql" "Fix users ID auto-generation"

echo "============================================"
echo -e "${GREEN}All migrations completed successfully!${NC}"
echo "============================================"
echo ""
echo "Your database is now ready to use."
echo ""
echo "Next steps:"
echo "1. Update your .env file with database credentials"
echo "2. Start the backend server: cd ../backend && npm run dev"
echo ""

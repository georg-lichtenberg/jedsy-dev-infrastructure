#!/bin/bash
# Script for accessing the Nebula Healthcheck Service database
# Usage: ./dbshell.sh [optional SQL command]

# Database parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="nebula-healthcheck-service"
DB_USER="nebula-healthcheck-service"
DB_PASSWORD="6UL2Vfq9GOQBm1UcnjSeqWKvsO0D4YZJ6yJflOkNsR7Z7Oul3mkKkTZniBipTgbb"

# Function to check if psql is installed
check_psql() {
  if ! command -v psql &> /dev/null; then
    echo "Error: PostgreSQL Client (psql) is not installed"
    echo "Please install it with: brew install postgresql"
    exit 1
  fi
}

# Function to connect to the database
connect_to_db() {
  # Set environment variable for password to avoid security warnings
  export PGPASSWORD="$DB_PASSWORD"
  
  # If an argument was passed, execute it as an SQL command
  if [ $# -gt 0 ]; then
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -c "$1"
  else
    # Otherwise start an interactive session
    echo "Connecting to Nebula Healthcheck Service database..."
    echo "Host: $DB_HOST:$DB_PORT"
    echo "Database: $DB_NAME"
    echo "User: $DB_USER"
    echo ""
    echo "Type '\q' to exit the session"
    echo "-----------------------------------------------"
    
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER"
  fi
  
  # Reset password environment variable
  unset PGPASSWORD
}

# Main program
check_psql
connect_to_db "$@"
#!/bin/bash
# Script for accessing the SERVICE_NAME database
# Usage: ./dbshell.sh [optional SQL command]

# Database parameters - Update these for your specific service
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="DB_NAME_PLACEHOLDER"
DB_USER="DB_USER_PLACEHOLDER"
DB_PASSWORD="DB_PASSWORD_PLACEHOLDER"

# Function to check if psql is installed
check_psql() {
  if ! command -v psql &> /dev/null; then
    echo "Error: PostgreSQL Client (psql) is not installed"
    echo "Please install it with: brew install postgresql"
    exit 1
  fi
}

# Function to check if the tunnel is running
check_tunnel() {
  if ! nc -z $DB_HOST $DB_PORT &> /dev/null; then
    echo "Warning: Cannot connect to database at $DB_HOST:$DB_PORT"
    echo "You may need to start a tunnel with dbtunnel.sh first"
    
    # Ask the user if they want to continue anyway
    read -p "Continue anyway? [y/N] " response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Exiting. Please start the tunnel with: ./dbtunnel.sh"
      exit 1
    fi
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
    echo "Connecting to SERVICE_NAME database..."
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
check_tunnel
connect_to_db "$@"
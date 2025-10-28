#!/bin/bash
# Script for extracting database schema from any PostgreSQL database
# Usage: ./extract_pg_schema.sh [database_name] [username] [optional_table_name]

# Default parameters - these should be overridden by command line args
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="${1:-nebula-vpn-pki}"
DB_USER="${2:-nebula-vpn-pki}"
DB_PASSWORD=""
OUTPUT_DIR="./schema_dumps"
TABLE_NAME="$3"

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display help message
show_help() {
  echo "Usage: $0 [database_name] [username] [optional_table_name]"
  echo ""
  echo "Examples:"
  echo "  $0 nebula-vpn-pki nebula-vpn-pki          # Extract schema for all tables"
  echo "  $0 nebula-healthcheck-service nebula-healthcheck-service endpoint_status  # Extract schema for a specific table"
  echo ""
  echo "Note: This script assumes a PostgreSQL server is running on localhost:5432."
  echo "Make sure to run ./scripts/dbtunnel.sh first to set up port forwarding."
}

# Function to check if psql is installed
check_psql() {
  if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: PostgreSQL Client (psql) is not installed${NC}"
    echo "Please install it with: brew install postgresql"
    exit 1
  fi
}

# Function to check if the tunnel is running
check_tunnel() {
  if ! nc -z $DB_HOST $DB_PORT &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to database at $DB_HOST:$DB_PORT${NC}"
    echo "Please start the tunnel first with: ./scripts/dbtunnel.sh"
    exit 1
  fi
  echo -e "${GREEN}Database connection to $DB_HOST:$DB_PORT is available${NC}"
}

# Function to prompt for password
get_password() {
  read -s -p "Enter database password for $DB_USER: " DB_PASSWORD
  echo ""
}

# Function to extract schema using SQL
extract_schema() {
  # Create output directory if it doesn't exist
  mkdir -p "$OUTPUT_DIR"
  
  echo -e "${GREEN}Setting up connection to ${DB_NAME} database...${NC}"
  
  # Set environment variable for password if provided
  if [ -n "$DB_PASSWORD" ]; then
    export PGPASSWORD="$DB_PASSWORD"
  fi
  
  # Test connection
  echo -e "${YELLOW}Testing database connection...${NC}"
  if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}Failed to connect to database.${NC}"
    
    # If we didn't have a password, ask for one
    if [ -z "$DB_PASSWORD" ]; then
      get_password
      export PGPASSWORD="$DB_PASSWORD"
      
      # Try again with the provided password
      if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
        echo -e "${RED}Failed to connect with provided password.${NC}"
        exit 1
      fi
    else
      exit 1
    fi
  fi
  
  echo -e "${GREEN}Connection successful.${NC}"
  
  if [ -n "$TABLE_NAME" ]; then
    # Extract schema for a specific table
    OUTPUT_FILE="$OUTPUT_DIR/${DB_NAME}_${TABLE_NAME}_schema.sql"
    echo -e "${YELLOW}Extracting schema for table: $TABLE_NAME${NC}"
    
    # Check if table exists
    TABLE_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = '$TABLE_NAME'
      );" | xargs)
    
    if [ "$TABLE_EXISTS" != "t" ]; then
      echo -e "${RED}Error: Table '$TABLE_NAME' does not exist in database '$DB_NAME'${NC}"
      # List available tables
      echo "Available tables:"
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\dt"
      exit 1
    fi
    
    # Create a complete CREATE TABLE statement
    echo "-- Table: $TABLE_NAME" > "$OUTPUT_FILE"
    echo "-- Generated on $(date)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Get column definitions
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT 'CREATE TABLE ' || quote_ident('$TABLE_NAME') || ' (' || CHR(10) ||
      string_agg(
        '    ' || quote_ident(column_name) || ' ' || 
        data_type || 
        CASE 
          WHEN character_maximum_length IS NOT NULL THEN '(' || character_maximum_length || ')'
          WHEN udt_name = 'numeric' AND numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL 
            THEN '(' || numeric_precision || ',' || numeric_scale || ')'
          ELSE '' 
        END || 
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END || 
        CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END,
        ',' || CHR(10)
      ) || CHR(10) || 
      ');'
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = '$TABLE_NAME'
      GROUP BY table_name;" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    
    # Get primary key constraints
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT 'ALTER TABLE ' || quote_ident('$TABLE_NAME') || ' ADD CONSTRAINT ' || 
             quote_ident(tc.constraint_name) || ' PRIMARY KEY (' ||
             string_agg(quote_ident(kcu.column_name), ', ') || ');'
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_schema = 'public' 
        AND tc.table_name = '$TABLE_NAME'
        AND tc.constraint_type = 'PRIMARY KEY'
      GROUP BY tc.constraint_name;" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    
    # Get foreign key constraints
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT 'ALTER TABLE ' || quote_ident(tc.table_name) || 
            ' ADD CONSTRAINT ' || quote_ident(tc.constraint_name) ||
            ' FOREIGN KEY (' || string_agg(quote_ident(kcu.column_name), ', ') || ')' ||
            ' REFERENCES ' || quote_ident(ccu.table_name) || 
            ' (' || string_agg(quote_ident(ccu.column_name), ', ') || ');'
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
      WHERE tc.table_schema = 'public' 
        AND tc.table_name = '$TABLE_NAME'
        AND tc.constraint_type = 'FOREIGN KEY'
      GROUP BY tc.constraint_name, tc.table_name, ccu.table_name;" >> "$OUTPUT_FILE"
    
    echo "" >> "$OUTPUT_FILE"
    
    # Get indexes (using pg_indexes)
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT indexdef || ';'
      FROM pg_indexes
      WHERE schemaname = 'public' AND tablename = '$TABLE_NAME' 
        AND indexname NOT LIKE '%_pkey';" >> "$OUTPUT_FILE"
    
  else
    # Extract schema for all tables
    OUTPUT_FILE="$OUTPUT_DIR/${DB_NAME}_full_schema.sql"
    echo -e "${YELLOW}Extracting schema for all tables in database: $DB_NAME${NC}"
    
    # Get all table names
    TABLES=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name;" | xargs)
    
    # Check if we found any tables
    if [ -z "$TABLES" ]; then
      echo -e "${RED}No tables found in database '$DB_NAME'${NC}"
      exit 1
    fi
    
    # Create header
    echo "-- Full schema dump for database: $DB_NAME" > "$OUTPUT_FILE"
    echo "-- Generated on $(date)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Process each table
    for TABLE in $TABLES; do
      echo -e "${GREEN}Processing table: $TABLE${NC}"
      
      echo "-- Table: $TABLE" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      
      # Get column definitions
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT 'CREATE TABLE ' || quote_ident('$TABLE') || ' (' || CHR(10) ||
        string_agg(
          '    ' || quote_ident(column_name) || ' ' || 
          data_type || 
          CASE 
            WHEN character_maximum_length IS NOT NULL THEN '(' || character_maximum_length || ')'
            WHEN udt_name = 'numeric' AND numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL 
              THEN '(' || numeric_precision || ',' || numeric_scale || ')'
            ELSE '' 
          END || 
          CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END || 
          CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END,
          ',' || CHR(10)
        ) || CHR(10) || 
        ');'
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = '$TABLE'
        GROUP BY table_name;" >> "$OUTPUT_FILE"
      
      echo "" >> "$OUTPUT_FILE"
      
      # Get primary key constraints
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT 'ALTER TABLE ' || quote_ident('$TABLE') || ' ADD CONSTRAINT ' || 
               quote_ident(tc.constraint_name) || ' PRIMARY KEY (' ||
               string_agg(quote_ident(kcu.column_name), ', ') || ');'
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = 'public' 
          AND tc.table_name = '$TABLE'
          AND tc.constraint_type = 'PRIMARY KEY'
        GROUP BY tc.constraint_name;" >> "$OUTPUT_FILE"
      
      echo "" >> "$OUTPUT_FILE"
      
      # Get foreign key constraints
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT 'ALTER TABLE ' || quote_ident(tc.table_name) || 
              ' ADD CONSTRAINT ' || quote_ident(tc.constraint_name) ||
              ' FOREIGN KEY (' || string_agg(quote_ident(kcu.column_name), ', ') || ')' ||
              ' REFERENCES ' || quote_ident(ccu.table_name) || 
              ' (' || string_agg(quote_ident(ccu.column_name), ', ') || ');'
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
        WHERE tc.table_schema = 'public' 
          AND tc.table_name = '$TABLE'
          AND tc.constraint_type = 'FOREIGN KEY'
        GROUP BY tc.constraint_name, tc.table_name, ccu.table_name;" >> "$OUTPUT_FILE"
      
      echo "" >> "$OUTPUT_FILE"
      
      # Get indexes (using pg_indexes)
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT indexdef || ';'
        FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = '$TABLE' 
          AND indexname NOT LIKE '%_pkey';" >> "$OUTPUT_FILE"
      
      echo "" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
    done
  fi
  
  echo -e "${GREEN}Schema saved to $OUTPUT_FILE${NC}"
  
  # Reset password environment variable
  unset PGPASSWORD
}

# Main program
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

check_psql
check_tunnel
extract_schema
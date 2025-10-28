#!/bin/bash
# Database statistics script for Nebula Healthcheck Service
# Usage: ./db_statistics.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}=== Nebula Healthcheck Service Database Statistics ===${NC}"
echo ""

# 1. Logs by category with unique endpoints
echo -e "${BLUE}1. Logs by Category (with unique endpoints):${NC}"
"$SCRIPT_DIR/dbshell.sh" "
SELECT 
    COUNT(*) as total_logs, 
    category, 
    COUNT(DISTINCT endpoint_id) as unique_endpoints 
FROM structured_logs 
GROUP BY category 
ORDER BY total_logs DESC;
"

echo ""
echo -e "${BLUE}2. Device Statistics by IP Address (Top 20):${NC}"
"$SCRIPT_DIR/dbshell.sh" "
SELECT 
    es.ip_address,
    es.device_name,
    es.device_type,
    COUNT(sl.id) as total_logs,
    COUNT(DISTINCT sl.category) as log_categories,
    MAX(sl.timestamp) as last_log_time
FROM endpoint_status es
LEFT JOIN structured_logs sl ON es.endpoint_id = sl.endpoint_id
WHERE es.ip_address IS NOT NULL
GROUP BY es.ip_address, es.device_name, es.device_type
ORDER BY total_logs DESC
LIMIT 20;
"

echo ""
echo -e "${BLUE}3. Device Statistics by Device ID and Name (Top 20):${NC}"
"$SCRIPT_DIR/dbshell.sh" "
SELECT 
    es.device_id,
    COALESCE(es.device_name, 'Unknown') as device_name,
    es.device_type,
    es.ip_address,
    COUNT(sl.id) as total_logs,
    COUNT(DISTINCT sl.category) as log_categories
FROM endpoint_status es
LEFT JOIN structured_logs sl ON es.endpoint_id = sl.endpoint_id
WHERE (es.device_id IS NOT NULL OR es.device_name IS NOT NULL)
GROUP BY es.device_id, es.device_name, es.device_type, es.ip_address
ORDER BY total_logs DESC
LIMIT 20;
"

echo ""
echo -e "${YELLOW}Statistics generated at: $(date)${NC}"
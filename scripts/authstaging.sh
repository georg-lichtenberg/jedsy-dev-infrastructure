#!/bin/bash

# auth.sh - Einfaches Skript zum Abrufen eines Tokens und Testen der PKI-API
# ---------------------------------------------------------

#!/bin/bash
set -e

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

KEYCLOAK_URL="https://auth.uphi.cc"
REALM="jedsy"
TOKEN_URL="${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token"

# User-Login-Daten (bitte anpassen!)
USER_EMAIL="glichtenberg@jedsy.com"
USER_PASSWORD="jDj4jIQNwJySjIm"

# vpn-dashboard
DASHBOARD_CLIENT_ID="PKI"
DASHBOARD_CLIENT_SECRET="Dr1CbUX8DR38UchPEZxGJtgdOwmF4Cey"

# nebula-vpn-pki
PKI_CLIENT_ID="PKI"
PKI_CLIENT_SECRET="MSbpzSv6FJp5nhyaMmhoSjAq50sIsu4X"

# Variablen-Prüfung
for var in USER_EMAIL USER_PASSWORD DASHBOARD_CLIENT_ID DASHBOARD_CLIENT_SECRET PKI_CLIENT_ID PKI_CLIENT_SECRET; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}Fehler: $var ist nicht gesetzt!${NC}"; exit 1
    fi
done

function test_login() {
    local SERVICE_NAME="$1"
    local CLIENT_ID="$2"
    local CLIENT_SECRET="$3"
    echo -e "${YELLOW}Teste User-Login für $SERVICE_NAME...${NC}"
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -d "client_id=${CLIENT_ID}" \
        -d "client_secret=${CLIENT_SECRET}" \
        -d "grant_type=password" \
        -d "username=${USER_EMAIL}" \
        -d "password=${USER_PASSWORD}" \
        "${TOKEN_URL}")
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')
    if echo "$BODY" | grep -q "access_token" && [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ User-Login für $SERVICE_NAME erfolgreich${NC}"
        echo "$BODY" | grep -o '"access_token":"[^"]*' | head -c 60; echo "..."
    else
        echo -e "${RED}❌ User-Login für $SERVICE_NAME fehlgeschlagen (HTTP $HTTP_CODE)${NC}"
        echo "$BODY"
    fi
}

test_login "vpn-dashboard" "$DASHBOARD_CLIENT_ID" "$DASHBOARD_CLIENT_SECRET"
test_login "nebula-vpn-pki" "$PKI_CLIENT_ID" "$PKI_CLIENT_SECRET"
echo "User-Login Test für nebula-vpn-pki..."
RESPONSE=$(curl -s -X POST \
    -d "client_id=${PKI_CLIENT_ID}" \
    -d "client_secret=${PKI_CLIENT_SECRET}" \
    -d "grant_type=password" \
    -d "username=${USER_EMAIL}" \
    -d "password=${USER_PASSWORD}" \
    "${TOKEN_URL}")
echo "$RESPONSE"

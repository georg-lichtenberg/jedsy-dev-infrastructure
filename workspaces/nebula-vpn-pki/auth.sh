#!/bin/bash

# auth.sh - Einfaches Skript zum Abrufen eines Tokens und Testen der PKI-API
# ---------------------------------------------------------

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Keycloak-Konfiguration
KEYCLOAK_URL="https://auth.uphi.cc"
REALM="jedsy"
CLIENT_ID="PKI"
CLIENT_SECRET="Dr1CbUX8DR38UchPEZxGJtgdOwmF4Cey"  # Das funktioniert!

# Token URL
TOKEN_URL="${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token"

echo -e "${YELLOW}Rufe Token ab...${NC}"

# Anfrage für den Token mit Client Credentials Flow
TOKEN_RESPONSE=$(curl -s -X POST \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "grant_type=client_credentials" \
    "${TOKEN_URL}")

# Prüfe, ob die Anfrage erfolgreich war
if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
    # Extrahiere den Token
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
    echo -e "${GREEN}✓ Token erfolgreich abgerufen${NC}"
    
    # Speichere den Token in einer Datei
    echo "$ACCESS_TOKEN" > auth_token.txt
    echo -e "${GREEN}✓ Token in auth_token.txt gespeichert${NC}"
    
    # Teste API-Endpunkt
    echo -e "\n${YELLOW}Teste API-Endpunkt: https://vpn.uphi.cc/admin/devices${NC}"
    API_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" https://vpn.uphi.cc/admin/devices)
    
    # Zeige Antwort
    echo -e "${GREEN}API-Antwort:${NC}"
    echo "$API_RESPONSE" | jq . 2>/dev/null || echo "$API_RESPONSE"
    
    echo -e "\n${GREEN}Für weitere Anfragen:${NC}"
    echo -e "curl -H \"Authorization: Bearer \$(cat auth_token.txt)\" https://vpn.uphi.cc/admin/devices"
else
    echo -e "${RED}✗ Fehler beim Abrufen des Tokens${NC}"
    echo -e "Antwort: $TOKEN_RESPONSE"
fi

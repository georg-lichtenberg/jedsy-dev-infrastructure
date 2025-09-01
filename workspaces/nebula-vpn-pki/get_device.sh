#!/bin/bash

# get_device.sh - Skript zum Abrufen eines Geräts per ID
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
CLIENT_SECRET="Dr1CbUX8DR38UchPEZxGJtgdOwmF4Cey"

# API-Basis-URL
API_BASE_URL="https://vpn.uphi.cc"

# Prüfen, ob eine Geräte-ID als Parameter übergeben wurde
if [ -z "$1" ]; then
    echo -e "${YELLOW}Verwendung: $0 <Geräte-ID>${NC}"
    echo -e "${YELLOW}Beispiel: $0 f55255d5-9efe-4f97-980f-72e978620636${NC}"
    
    # Frage nach der Geräte-ID
    read -p "Bitte gib die Geräte-ID ein: " DEVICE_ID
    
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}Keine Geräte-ID angegeben. Beende...${NC}"
        exit 1
    fi
else
    DEVICE_ID="$1"
fi

echo -e "${YELLOW}Hole Geräteinformationen für ID: ${DEVICE_ID}${NC}"

# Token URL
TOKEN_URL="${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token"

# Prüfe, ob ein gültiger Token in auth_token.txt existiert
if [ -f "auth_token.txt" ]; then
    echo -e "${GREEN}Verwende vorhandenen Token aus auth_token.txt${NC}"
    ACCESS_TOKEN=$(cat auth_token.txt)
else
    echo -e "${YELLOW}Kein Token gefunden, rufe neuen Token ab...${NC}"
    
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
    else
        echo -e "${RED}✗ Fehler beim Abrufen des Tokens${NC}"
        echo -e "Antwort: $TOKEN_RESPONSE"
        exit 1
    fi
fi

# API-Endpunkt für ein spezifisches Gerät
DEVICE_URL="${API_BASE_URL}/admin/devices/${DEVICE_ID}"

# Geräteinformationen abrufen
echo -e "\n${YELLOW}Rufe Geräteinformationen ab: ${DEVICE_URL}${NC}"
DEVICE_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "${DEVICE_URL}")

# Prüfe auf Fehler in der Antwort
if echo "$DEVICE_RESPONSE" | grep -q "error\|Error\|<!DOCTYPE"; then
    echo -e "${RED}✗ Fehler beim Abrufen der Geräteinformationen${NC}"
    
    # Prüfe auf HTML-Antwort (meist Fehlerseite)
    if echo "$DEVICE_RESPONSE" | grep -q "<!DOCTYPE"; then
        echo -e "${RED}Die API hat eine HTML-Seite zurückgegeben. Möglicherweise existiert das Gerät nicht oder die API unterstützt diesen Endpunkt nicht.${NC}"
        echo -e "${YELLOW}Alternativ können wir versuchen, alle Geräte abzurufen und nach der ID zu filtern:${NC}"
        echo -e "curl -H \"Authorization: Bearer \$(cat auth_token.txt)\" ${API_BASE_URL}/admin/devices"
    else
        echo -e "Antwort: $DEVICE_RESPONSE"
    fi
else
    # Zeige die Geräteinformationen
    echo -e "${GREEN}Geräteinformationen:${NC}"
    echo "$DEVICE_RESPONSE" | jq . 2>/dev/null || echo "$DEVICE_RESPONSE"
fi

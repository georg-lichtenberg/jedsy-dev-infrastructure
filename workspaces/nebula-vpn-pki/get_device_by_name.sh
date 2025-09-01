#!/bin/bash

# get_device_by_name.sh - Skript zum Abrufen eines Geräts anhand des Namens
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

# Prüfen, ob ein Gerätename als Parameter übergeben wurde
if [ -z "$1" ]; then
    echo -e "${YELLOW}Verwendung: $0 <Gerätename>${NC}"
    echo -e "${YELLOW}Beispiel: $0 M24-12${NC}"
    
    # Frage nach dem Gerätenamen
    read -p "Bitte gib den Gerätenamen ein: " DEVICE_NAME
    
    if [ -z "$DEVICE_NAME" ]; then
        echo -e "${RED}Kein Gerätename angegeben. Beende...${NC}"
        exit 1
    fi
else
    DEVICE_NAME="$1"
fi

echo -e "${YELLOW}Hole Geräteinformationen für Name: ${DEVICE_NAME}${NC}"

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

# API-Endpunkt für ein Gerät anhand des Namens
DEVICE_URL="${API_BASE_URL}/admin/device/by-name/${DEVICE_NAME}"

# Geräteinformationen abrufen
echo -e "\n${YELLOW}Rufe Geräteinformationen ab: ${DEVICE_URL}${NC}"
DEVICE_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "${DEVICE_URL}")

# Prüfe auf Fehler in der Antwort
if echo "$DEVICE_RESPONSE" | grep -q "error\|Error\|<!DOCTYPE"; then
    # Extrahiere den HTML-Titel für bessere Fehlermeldungen
    HTML_TITLE=$(echo "$DEVICE_RESPONSE" | grep -o '<title>.*</title>' | sed 's/<title>\(.*\)<\/title>/\1/')
    
    # Wenn HTML-Antwort gefunden wurde
    if echo "$DEVICE_RESPONSE" | grep -q "<!DOCTYPE"; then
        # Prüfe, ob es sich um eine Detailseite handelt
        if echo "$HTML_TITLE" | grep -q "Device"; then
            echo -e "${GREEN}✓ Gerät gefunden.${NC}"
            echo -e "${YELLOW}Die API gibt eine HTML-Seite zurück. Inhalt:${NC}"
            
            # Extrahiere wichtige Informationen aus der HTML-Antwort
            NAME=$(echo "$DEVICE_RESPONSE" | grep -o '<h1[^>]*>.*</h1>' | sed 's/<h1[^>]*>\(.*\)<\/h1>/\1/' | sed 's/<[^>]*>//g')
            ID=$(echo "$DEVICE_RESPONSE" | grep -o 'ID:</strong> [^<]*' | sed 's/ID:<\/strong> \(.*\)/\1/')
            TYPE=$(echo "$DEVICE_RESPONSE" | grep -o 'Type:</strong> [^<]*' | sed 's/Type:<\/strong> \(.*\)/\1/')
            DESCRIPTION=$(echo "$DEVICE_RESPONSE" | grep -o 'Description:</strong> [^<]*' | sed 's/Description:<\/strong> \(.*\)/\1/')
            CREATED=$(echo "$DEVICE_RESPONSE" | grep -o 'Created At:</strong> [^<]*' | sed 's/Created At:<\/strong> \(.*\)/\1/')
            UPDATED=$(echo "$DEVICE_RESPONSE" | grep -o 'Updated At:</strong> [^<]*' | sed 's/Updated At:<\/strong> \(.*\)/\1/')
            
            echo -e "Name: $NAME"
            echo -e "ID: $ID"
            echo -e "Type: $TYPE"
            echo -e "Description: $DESCRIPTION"
            echo -e "Created At: $CREATED"
            echo -e "Updated At: $UPDATED"
            
            # Extrahiere VPN-Endpunkte, falls vorhanden
            if echo "$DEVICE_RESPONSE" | grep -q "VPN Endpoints"; then
                echo -e "\n${YELLOW}VPN Endpoints:${NC}"
                echo "$DEVICE_RESPONSE" | grep -o '<tr>.*</tr>' | grep -v '<th>' | sed 's/<[^>]*>//g' | sed '/^$/d'
            fi
        else
            # Andere Fehlerseite
            echo -e "${RED}✗ Fehler beim Abrufen der Geräteinformationen${NC}"
            if [ ! -z "$HTML_TITLE" ]; then
                echo -e "${RED}Fehler: $HTML_TITLE${NC}"
            else
                echo -e "${RED}Die API hat eine HTML-Seite zurückgegeben. Möglicherweise existiert das Gerät nicht oder die API unterstützt diesen Endpunkt nicht.${NC}"
            fi
        fi
    else
        # Kein HTML, aber dennoch ein Fehler
        echo -e "${RED}✗ Fehler beim Abrufen der Geräteinformationen${NC}"
        echo -e "Antwort: $DEVICE_RESPONSE"
    fi
else
    # Zeige die Geräteinformationen
    echo -e "${GREEN}Geräteinformationen:${NC}"
    echo "$DEVICE_RESPONSE" | jq . 2>/dev/null || echo "$DEVICE_RESPONSE"
fi

#!/bin/bash

# Einfaches Script um einen Device per Name abzufragen
# --------------------------------------------------

# Keycloak-Konfiguration
KEYCLOAK_URL="https://auth.uphi.cc"
REALM="jedsy"
CLIENT_ID="PKI"
CLIENT_SECRET="Dr1CbUX8DR38UchPEZxGJtgdOwmF4Cey"

# API-Basis-URL
API_BASE_URL="https://vpn.uphi.cc"

# Gerätename aus Argument oder Eingabe
DEVICE_NAME="$1"
if [ -z "$DEVICE_NAME" ]; then
    read -p "Gerätename: " DEVICE_NAME
    if [ -z "$DEVICE_NAME" ]; then
        echo "Kein Gerätename angegeben. Beende..."
        exit 1
    fi
fi

# Token abrufen
TOKEN_RESPONSE=$(curl -s -X POST \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "grant_type=client_credentials" \
    "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token")

# Token extrahieren
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')

# API aufrufen und Ergebnis ausgeben
echo "Versuche API-Endpunkt:"
echo "curl -s -H \"Authorization: Bearer $ACCESS_TOKEN\" \"${API_BASE_URL}/api/device/by-name/${DEVICE_NAME}\""
echo "---------------------"
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "${API_BASE_URL}/api/device/by-name/${DEVICE_NAME}"

echo -e "\n\nVersuche alternativen API-Endpunkt:"
echo "curl -s -H \"Authorization: Bearer $ACCESS_TOKEN\" \"${API_BASE_URL}/api/devices/name/${DEVICE_NAME}\""
echo "---------------------"
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "${API_BASE_URL}/api/devices/name/${DEVICE_NAME}"

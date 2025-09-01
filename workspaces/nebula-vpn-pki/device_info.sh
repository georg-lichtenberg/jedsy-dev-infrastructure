#!/bin/bash

# Einfaches Script für API-Update des device_type
# -------------------------------------

# Keycloak-Konfiguration
KEYCLOAK_URL="https://auth.uphi.cc"
REALM="jedsy"
CLIENT_ID="PKI"
CLIENT_SECRET="Dr1CbUX8DR38UchPEZxGJtgdOwmF4Cey"

# API-Basis-URL
API_BASE_URL="https://vpn.uphi.cc"

# Prüfen ob Gerätename und Typ als Parameter übergeben wurden
if [ "$#" -lt 2 ]; then
    echo "Verwendung: $0 <Gerätename> <Device-Type>"
    echo "Gültige Device-Types:"
    echo "  - drone"
    echo "  - linux_computer"
    echo "  - windows_laptop"
    echo "  - macbook"
    echo "  - iphone"
    echo "  - android_phone"
    echo "Beispiel: $0 M24-12 drone"
    exit 1
fi

DEVICE_NAME="$1"
DEVICE_TYPE="$2"

# Validiere device_type
VALID_TYPES=("drone" "linux_computer" "windows_laptop" "macbook" "iphone" "android_phone")
VALID=0
for type in "${VALID_TYPES[@]}"; do
    if [ "$DEVICE_TYPE" = "$type" ]; then
        VALID=1
        break
    fi
done

if [ $VALID -eq 0 ]; then
    echo "Fehler: Ungültiger Device-Type: $DEVICE_TYPE"
    echo "Gültige Device-Types:"
    echo "  - drone"
    echo "  - linux_computer"
    echo "  - windows_laptop"
    echo "  - macbook"
    echo "  - iphone"
    echo "  - android_phone"
    exit 1
fi

# Token abrufen
echo "Hole Token..."
TOKEN_RESPONSE=$(curl -s -X POST \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "grant_type=client_credentials" \
    "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')

# Geräteinformationen abfragen
echo "Prüfe ob Gerät existiert: ${DEVICE_NAME}"
DEVICE_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "${API_BASE_URL}/admin/device/by-name/${DEVICE_NAME}")

# Prüfen, ob Gerät gefunden wurde (nach ID suchen)
DEVICE_ID=$(echo "$DEVICE_RESPONSE" | grep -o 'ID:</strong> <code>[^<]*' | sed 's/ID:<\/strong> <code>\(.*\)/\1/')

if [ -z "$DEVICE_ID" ]; then
    echo "Fehler: Gerät '$DEVICE_NAME' nicht gefunden!"
    exit 1
fi

echo "Gerät gefunden: $DEVICE_NAME (ID: $DEVICE_ID)"

# Aktuellen Typ extrahieren
CURRENT_TYPE=$(echo "$DEVICE_RESPONSE" | grep -o 'Type:</strong> [^<]*' | sed 's/Type:<\/strong> \(.*\)/\1/')
echo "Aktueller Typ: $CURRENT_TYPE"

# Mit diesen Informationen können Sie die Datenbank direkt aktualisieren
echo "Um den device_type zu aktualisieren, führen Sie bitte den folgenden SQL-Befehl in der Datenbank aus:"
echo ""
echo "UPDATE device"
echo "SET device_type = '$DEVICE_TYPE', updated_at = NOW()"
echo "WHERE id = '$DEVICE_ID';"
echo ""
echo "Alternativ können Sie auch die Webanwendung nutzen und auf"
echo "${API_BASE_URL}/admin/device/by-name/${DEVICE_NAME}"
echo "gehen und dort das Gerät bearbeiten."

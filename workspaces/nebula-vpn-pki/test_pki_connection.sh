#!/bin/bash

# Skript zum direkten Zugriff auf die PKI-Admin-Oberfläche mit curl
# Dieses Skript versucht, die Admin-Oberfläche direkt aufzurufen und Cookies zu speichern

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# PKI-Konfiguration
PKI_URL="https://vpn.uphi.cc"
COOKIES_FILE="/tmp/pki_cookies.txt"

# Benutzerdaten für die Authentifizierung
echo -e "${YELLOW}Bitte geben Sie Ihre PKI-Anmeldedaten ein${NC}"
read -p "E-Mail: " EMAIL
read -s -p "Passwort: " PASSWORD
echo ""

# Ausgabe der Konfiguration
echo -e "${YELLOW}PKI-Verbindungstest (direkte Anmeldung)${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo -e "PKI-URL: ${PKI_URL}"
echo -e "E-Mail: ${EMAIL}"
echo -e ""

# Löscht vorhandene Cookies
rm -f "$COOKIES_FILE"

# 1. Schritt: Zuerst die Login-Seite abrufen, um Cookies und CSRF-Token zu erhalten
echo -e "${YELLOW}Rufe Login-Seite ab...${NC}"
LOGIN_PAGE=$(curl -s -c "$COOKIES_FILE" "${PKI_URL}/login")

# 2. Schritt: Login durchführen
echo -e "${YELLOW}Führe Login durch...${NC}"
LOGIN_RESPONSE=$(curl -s -L -b "$COOKIES_FILE" -c "$COOKIES_FILE" \
  -d "email=${EMAIL}" \
  -d "password=${PASSWORD}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  "${PKI_URL}/login")

# 3. Schritt: Testen, ob wir Zugriff auf die Admin-Geräteseite haben
echo -e "${YELLOW}Teste Zugriff auf Admin-Geräteseite...${NC}"
ADMIN_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/pki_admin_response.html \
  -b "$COOKIES_FILE" "${PKI_URL}/admin/devices")

if [ "$ADMIN_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ Admin-Geräteseite ist zugänglich!${NC}"
    
    # Prüfen, ob die Antwort eine Login-Seite enthält
    if grep -q "login" /tmp/pki_admin_response.html; then
        echo -e "${RED}✗ Die Antwort enthält einen Login-Verweis. Die Anmeldung war nicht erfolgreich.${NC}"
    else
        echo -e "${GREEN}✓ Die Antwort scheint eine gültige Admin-Seite zu sein.${NC}"
        echo -e "Die Antwort wurde in /tmp/pki_admin_response.html gespeichert."
        
        # Für die weitere Untersuchung speichern wir auch die Cookies
        echo -e "${GREEN}✓ Cookies wurden in $COOKIES_FILE gespeichert.${NC}"
        echo -e "Sie können mit diesem Befehl auf andere PKI-Endpunkte zugreifen:"
        echo -e "${GREEN}curl -b $COOKIES_FILE https://vpn.uphi.cc/admin/devices${NC}"
    fi
else
    echo -e "${RED}✗ Admin-Geräteseite ist NICHT zugänglich (HTTP $ADMIN_RESPONSE)${NC}"
    echo -e "Die Antwort wurde in /tmp/pki_admin_response.html gespeichert."
fi

echo -e "\n${YELLOW}Test abgeschlossen.${NC}"

echo -e "\n${YELLOW}Test abgeschlossen.${NC}"

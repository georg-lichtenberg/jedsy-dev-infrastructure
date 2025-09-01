#!/bin/bash

KEYCLOAK_URL="https://auth.uphi.cc"
REALM="jedsy"
PKI_CLIENT_ID="PKI"
PKI_CLIENT_SECRET="JY7sd16vFW9rSfwmZ9WKOY9JEGug3ugt"
USER_EMAIL="glichtenberg@jedsy.com"
USER_PASSWORD="jDj4jIQNwJySjIm"
TOKEN_URL="${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token"

echo "Teste User-Login für PKI..."
RESPONSE=$(curl -s -X POST \
  -d "client_id=${PKI_CLIENT_ID}" \
  -d "client_secret=${PKI_CLIENT_SECRET}" \
  -d "grant_type=password" \
  -d "username=${USER_EMAIL}" \
  -d "password=${USER_PASSWORD}" \
  "${TOKEN_URL}")

echo "$RESPONSE"
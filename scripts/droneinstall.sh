#!/bin/bash
set -e

# ========================
# Base directory
# ========================
PKI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/usr/local/etc/nebula"
BIN_DIR="/usr/local/bin/"

# ========================
# Configuration
# ========================

# Set variables (all injected by template except PASSWORD)
USERNAME="glichtenberg@jedsy.com"
PASSWORD="jDj4jIQNwJySjIm"
KEYCLOAK_URL="https://auth.uphi.cc"
PKI_URL="https://vpn.uphi.cc"
LICENSE_KEY="33ES-GMAN-7X8L-99U9"
CA_DECRYPT="9NZY*Y346B83!jqkkhG*"

# Prompt for PASSWORD
read -s -p "🔑 Enter your password: " PASSWORD
echo

# Confirm if needed
if [[ -z "$PASSWORD" ]]; then
  echo "❌ PASSWORD is required!"
  exit 1
fi

echo "🔧 Configuration:"
echo "  USERNAME: $USERNAME"
echo "  PASSWORD: ********"
echo "  CA_DECRYPT: ********"
echo "  KEYCLOAK_URL: $KEYCLOAK_URL"
echo "  PKI_URL: $PKI_URL"
echo "  LICENSE_KEY: $LICENSE_KEY"

OUT_DIR="$PKI_ROOT/cert_output"
NEBULA_BIN_DIR="$PKI_ROOT/nebula_bin"
NEBULA_CONFIG="config.yaml"
REQUEST_FILE="$PKI_ROOT/request.json"
CERT_ZIP="$PKI_ROOT/cert.zip"
INTERFACE_TYPE=${INTERFACE_TYPE:-1}

# ========================
# Authentication
# ========================
KEYCLOAK_REALM="jedsy"
TOKEN_ENDPOINT="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token"
CLIENT_ID="PKI"
CLIENT_SECRET="Dr1CbUX8DR38UchPEZxGJtgdOwmF4Cey"

# --- Request Access Token ---
RESPONSE=$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "username=${USERNAME}" \
  -d "password=${PASSWORD}")

ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r .access_token)

if [[ "$ACCESS_TOKEN" == "null" || -z "$ACCESS_TOKEN" ]]; then
  echo "❌ Failed to obtain access token"
  echo "📨 Full Keycloak response:"
  echo "$RESPONSE"
  exit 1
fi

echo "✅ Access token obtained."

# --- Extract and decode JWT payload with proper Base64 padding ---
PAYLOAD_B64=$(echo "$ACCESS_TOKEN" | cut -d '.' -f2)

# Add padding if necessary
REMAINDER=$((${#PAYLOAD_B64} % 4))
if [ $REMAINDER -eq 2 ]; then
  PAYLOAD_B64="${PAYLOAD_B64}=="
elif [ $REMAINDER -eq 3 ]; then
  PAYLOAD_B64="${PAYLOAD_B64}="
elif [ $REMAINDER -eq 1 ]; then
  PAYLOAD_B64="${PAYLOAD_B64}==="  # Extremfall
fi

# Decode Base64 (macOS and Linux compatible)
if base64 --help 2>&1 | grep -q 'GNU'; then
  PAYLOAD=$(echo "$PAYLOAD_B64" | base64 -d 2>/dev/null)
else
  PAYLOAD=$(echo "$PAYLOAD_B64" | base64 -D 2>/dev/null)
fi

if ! echo "$PAYLOAD" | jq . >/dev/null 2>&1; then
  echo "❌ Invalid JWT payload – cannot parse JSON"
  echo "📦 Raw Payload:"
  echo "$PAYLOAD"
  exit 1
fi

# --- Extract roles ---
REALM_ROLES=$(echo "$PAYLOAD" | jq -r '.realm_access.roles[]?' 2>/dev/null)
CLIENT_ROLES=$(echo "$PAYLOAD" | jq -r ".resource_access.\"${CLIENT_ID}\".roles[]?" 2>/dev/null)

echo -e "\n🧾 Client Roles (${CLIENT_ID}):"
echo "$CLIENT_ROLES"

# ========================
# Check required role
# ========================
if echo "$CLIENT_ROLES" | grep -qE "(pki_user|pki_admin)"; then
  echo "✅ User has required role: pki_user or pki_admin"
else
  echo "⛔ User lacks required role (pki_user or pki_admin). Aborting."
  exit 1
fi

# ========================
# MAC address
# ========================
echo "🔍 Detecting MAC address..."
if command -v ip &>/dev/null; then
  MAC_ADDRESS=$(ip link | grep -m1 -Eo 'ether ([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | awk '{print $2}')
else
  MAC_ADDRESS=$(ifconfig | grep -Eo '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | head -n 1)
fi

if [ -z "$MAC_ADDRESS" ]; then
  echo "❌ MAC address not found"; exit 1
fi
echo "✅ MAC: $MAC_ADDRESS"

# ========================
# Architecture
# ========================
echo "🔍 Detecting architecture..."
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
  Linux) OS_NAME="linux" ;;
  Darwin) OS_NAME="darwin" ;;
  *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64) ARCH_NAME="amd64" ;;
  arm64|aarch64) ARCH_NAME="arm64" ;;
  armv6l) ARCH_NAME="armv6l" ;;
  *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

ARCHITECTURE="${OS_NAME}_${ARCH_NAME}"
echo "✅ Architecture: $ARCHITECTURE"

# ========================
# Device name
# ========================
DEVICE_NAME=${DEVICE_NAME:-$(hostname)}
echo "💻 Device name: $DEVICE_NAME"

# Detect device type
echo "🔍 Detecting device type..."
case "$OS" in
  Linux)
    if [[ "$ARCH_NAME" == "arm64" ]]; then
      DEVICE_TYPE="drone"
      INTERFACE_TYPE=1 # main
    elif [[ "$ARCH_NAME" == "armv6l" ]]; then
      DEVICE_TYPE="drone"
      INTERFACE_TYPE=2 # FTS
    else
      DEVICE_TYPE="linux_computer"
      INTERFACE_TYPE=1 # main
    fi
    ;;
  Darwin)
    DEVICE_TYPE="macbook"
    INTERFACE_TYPE=1 # main
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    DEVICE_TYPE="windows_laptop"
    INTERFACE_TYPE=1 # main
    ;;
  *)
    DEVICE_TYPE="unknown"
    ;;
esac
echo "✅ Device type: $DEVICE_TYPE"
echo "✅ Interface type: $INTERFACE_TYPE"

# ========================
# Create request.json
# ========================
echo "📄 Creating request.json..."
cat > "$REQUEST_FILE" <<EOF
{
  "email": "glichtenberg@jedsy.com",
  "password": "9NZY*Y346B83!jqkkhG*",
  "groups": ["computers"],
  "license_key": "33ES-GMAN-7X8L-99U9",
  "mac_address": "$MAC_ADDRESS",
  "architecture": "$ARCHITECTURE",
  "device_name": "$DEVICE_NAME",
  "device_type": "$DEVICE_TYPE",
  "interface_type": $INTERFACE_TYPE
}
EOF

# ========================
# Send request & extract token
# ========================
echo "🚀 Sending request to https://vpn.uphi.cc/cert/request..."
RESPONSE=$(curl -s -X POST "https://vpn.uphi.cc/cert/request" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data @"$REQUEST_FILE")
  
echo "⚠️  Using CA_DECRYPT: 9NZY*Y346B83!jqkkhG*"

TOKEN=$(echo "$RESPONSE" | grep -o '"download_token":"[^"]*"' | cut -d':' -f2 | tr -d '"')
if [ -z "$TOKEN" ]; then echo "❌ No token in response: $RESPONSE"; exit 1; fi
echo "✅ Token: $TOKEN"

# ========================
# Download & unzip certificate bundle
# ========================
echo "⬇️ Downloading certificate ZIP..."
curl -s -o "$CERT_ZIP" "https://vpn.uphi.cc/cert/download/$TOKEN"
mkdir -p "$OUT_DIR"
unzip -o "$CERT_ZIP" -d "$OUT_DIR"

# ========================
# Patch config.yaml (via sed)
# ========================
echo "🛠️ Patching config.yaml..."
CONFIG_TEMPLATE="$OUT_DIR/$NEBULA_CONFIG"
CONFIG_PATCHED="$OUT_DIR/config.patched.yaml"

if [ ! -f "$CONFIG_TEMPLATE" ]; then
  echo "❌ Config template not found: $CONFIG_TEMPLATE"
  exit 1
fi

# ➕ Temporär einen Slash anhängen, falls nicht vorhanden
ESCAPED_CONFIG_DIR=$(printf '%s/\n' "$CONFIG_DIR" | sed 's|//*$|/|; s/[\/&]/\\&/g')

# sed mit sicherer Ersetzung
sed "s/__CONFIG_DIR__/${ESCAPED_CONFIG_DIR}/g" "$CONFIG_TEMPLATE" > "$CONFIG_PATCHED"

# Vorschau
echo "🔍 Preview of patched config.yaml:"
grep '__CONFIG_DIR__' "$CONFIG_PATCHED" && echo "❌ Placeholder not replaced!" && exit 1
head "$CONFIG_PATCHED"

# ========================
# Determine Nebula binary URL
# ========================
echo "🌐 Determining Nebula binary..."
case "$ARCHITECTURE" in
  linux_armv6l)  URL="https://github.com/slackhq/nebula/releases/download/v1.9.5/nebula-linux-arm-6.tar.gz" ;;
  linux_amd64)   URL="https://github.com/slackhq/nebula/releases/download/v1.9.5/nebula-linux-amd64.tar.gz" ;;
  linux_arm64)   URL="https://github.com/slackhq/nebula/releases/download/v1.9.5/nebula-linux-arm64.tar.gz" ;;
  darwin_amd64|darwin_arm64)
                URL="https://github.com/slackhq/nebula/releases/download/v1.9.5/nebula-darwin.zip" ;;
  *) echo "❌ Unsupported architecture: $ARCHITECTURE"; exit 1 ;;
esac

# ========================
# Download & extract Nebula
# ========================
echo "📦 Downloading Nebula: $URL"
mkdir -p "$NEBULA_BIN_DIR"
FILENAME="$PKI_ROOT/nebula_bundle.${URL##*.}"
curl -L -o "$FILENAME" "$URL"

echo "📂 Extracting Nebula binary..."
if [[ "$FILENAME" == *.zip ]]; then
  unzip -o "$FILENAME" -d "$NEBULA_BIN_DIR"
else
  tar -xzf "$FILENAME" -C "$NEBULA_BIN_DIR"
fi

# ========================
# Install Nebula binary
# ========================
NEBULA_BIN=$(find "$NEBULA_BIN_DIR" -type f -name nebula)
if [ ! -f "$NEBULA_BIN" ]; then echo "❌ nebula binary not found"; exit 1; fi

echo "🛠️ Installing Nebula to $BIN_DIR..."
sudo install -m 755 "$NEBULA_BIN" "$BIN_DIR/nebula"

# ========================
# Install config and certs
# ========================
echo "📁 Installing certs to $CONFIG_DIR..."
sudo mkdir -p "$CONFIG_DIR"
sudo cp "$OUT_DIR/"*.crt "$OUT_DIR/"*.key "$CONFIG_DIR/"

echo "📁 Installing patched config.yaml to $CONFIG_DIR..."
sudo cp "$CONFIG_PATCHED" "$CONFIG_DIR/config.yaml"

# ========================
# Create OS-specific service
# ========================
if [ "$OS" = "Linux" ]; then
  echo "🔧 Creating systemd service..."
  sudo tee /etc/systemd/system/nebula.service > /dev/null <<EOF
[Unit]
Description=Nebula VPN
After=network.target

[Service]
ExecStart=$BIN_DIR/nebula -config $CONFIG_DIR/config.yaml
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable nebula.service
  sudo systemctl restart nebula.service
  echo "✅ Nebula systemd service is running."

elif [ "$OS" = "Darwin" ]; then
  echo "🔧 Creating launchd service..."
  sudo tee /Library/LaunchDaemons/com.nebula.vpn.plist > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.nebula.vpn</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN_DIR/nebula</string>
    <string>-config</string>
    <string>$CONFIG_DIR/config.yaml</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>UserName</key><string>root</string>
  <key>StandardOutPath</key><string>/var/log/nebula.out.log</string>
  <key>StandardErrorPath</key><string>/var/log/nebula.err.log</string>
</dict>
</plist>
EOF

  sudo launchctl unload /Library/LaunchDaemons/com.nebula.vpn.plist 2>/dev/null || true
  sudo launchctl load /Library/LaunchDaemons/com.nebula.vpn.plist
  echo "✅ Nebula launchd service is running."

else
  echo "❌ No init system support for OS: $OS"
  exit 1
fi

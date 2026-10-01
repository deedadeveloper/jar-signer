#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$HOME/projects/apk-tools"
OUTPUT_DIR="$HOME/projects/signed-apks"
KEYSTORE="$WORKSPACE/toolchain_master.p12"

# Load secure credentials
SECRETS_FILE="$HOME/.apk_secrets"
if [ -f "$SECRETS_FILE" ]; then
    source "$SECRETS_FILE"
else
    echo "[-] Error: Secrets file not found at $SECRETS_FILE"
    exit 1
fi

APK_FILE="${1:-}"
MODE="${2:-quick}"

if [ -z "$APK_FILE" ] || [ ! -f "$APK_FILE" ]; then
    echo "[-] Error: Please specify a valid target APK file."
    echo "Usage: ./apk_workflow.sh <path_to_apk> [quick|full]"
    exit 1
fi

echo "[*] Starting workflow for: $(basename "$APK_FILE") (Mode: $MODE)"

if [ ! -f "$KEYSTORE" ]; then
    echo "[-] Keystore not found. Generating fresh PKCS12 keystore..."
    keytool -genkeypair -v \
      -storetype PKCS12 \
      -keystore "$KEYSTORE" \
      -alias "$KEYSTORE_ALIAS" \
      -keyalg RSA \
      -keysize 2048 \
      -validity 10000 \
      -storepass "$KEYSTORE_PASS" \
      -keypass "$KEYSTORE_PASS" \
      -dname "CN=DeedaToolchain, OU=Mod, O=Local, L=Unknown, ST=Unknown, C=US"
    echo "[+] PKCS12 Keystore generated successfully."
else
    echo "[+] Keystore verified at: $KEYSTORE"
fi

if ! unzip -t "$APK_FILE" > /dev/null 2>&1; then
    echo "[-] Error: Invalid or corrupted APK file."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
BASENAME=$(basename "$APK_FILE" .apk)
SIGNED_APK="$OUTPUT_DIR/${BASENAME}_signed.apk"
cp "$APK_FILE" "$SIGNED_APK"

jarsigner -verbose \
  -keystore "$KEYSTORE" \
  -storepass "$KEYSTORE_PASS" \
  -keypass "$KEYSTORE_PASS" \
  "$SIGNED_APK" "$KEYSTORE_ALIAS"

echo "[✔] Success! Signed APK saved to: $SIGNED_APK"

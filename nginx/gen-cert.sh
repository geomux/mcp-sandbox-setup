#!/usr/bin/env bash
# gen-cert.sh
# Creates a self-signed keypair for nginx. Run this shell script once, PRIOR to 'docker compose up'.

set -euo pipefail
cd "$(dirname "$0")"

CN="${1:-$(hostname)}"
IP="$(hostname -I | awk '{print $1}')"

mkdir -p tls

if [ -f tls/mcp.crt ]; then
    echo "tls/mcp.crt already exists."
    echo "Delete tls/mcp.crt and tls/mcp.key if you want to create a new one."
    echo "(It is import to create a new one if existing one is an old .crt)"
    exit 0
fi

openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout tls/mcp.key -out tls/mcp.crt \
    -subj "/CN=${CN}" \
    -addext "subjectAltName=DNS:${CN},DNS:${CN}.local,DNS:localhost,IP:${IP},IP:127.0.0.1"

chmod 600 tls/mcp.key

echo
echo "Created nginx/tls/mcp.crt and nginx/tls/mcp.key"
echo "Valid for ${CN}, ${CN}.local, localhost, ${IP}, 127.0.0.1"
echo "Copy the .crt (NEVER the .key) to any machine that will connect directly."


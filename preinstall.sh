#!/bin/bash
set -e

SUNSHINE_CONFIG_DIR="/root/.config/sunshine"
SUNSHINE_CERT="${SUNSHINE_CONFIG_DIR}/cert.pem"
SUNSHINE_KEY="${SUNSHINE_CONFIG_DIR}/key.pem"
CERT_DAYS="${SUNSHINE_CERT_DAYS:-3650}"
CERT_SUBJECT="${SUNSHINE_CERT_SUBJECT:-/CN=sunshine.local}"

mkdir -p "${SUNSHINE_CONFIG_DIR}"

if [ -f "${SUNSHINE_CERT}" ] && [ -f "${SUNSHINE_KEY}" ]; then
    echo "Sunshine TLS certificates already exist, skipping generation."
    exit 0
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl is required to generate Sunshine certificates."
    exit 1
fi

echo "Generating Sunshine TLS certificates (first boot)..."
openssl req -x509 -newkey rsa:4096 -sha256 \
    -keyout "${SUNSHINE_KEY}" \
    -out "${SUNSHINE_CERT}" \
    -days "${CERT_DAYS}" \
    -nodes \
    -subj "${CERT_SUBJECT}" >/dev/null 2>&1

chmod 600 "${SUNSHINE_KEY}"
chmod 644 "${SUNSHINE_CERT}"

echo "Sunshine TLS certificates generated at ${SUNSHINE_CONFIG_DIR}."
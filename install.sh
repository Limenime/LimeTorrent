#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Limenime/LimeTorrent/releases/latest/download"

# Deteksi arsitektur
case "$(uname -m)" in
    x86_64)
        FILE="LimeTorrent-linux-amd64.tgz"
        ;;
    aarch64|arm64)
        FILE="LimeTorrent-linux-arm64.tgz"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading $FILE..."

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_URL/$FILE" -o "$TMP_DIR/LimeTorrent.tgz"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$REPO_URL/$FILE" -O "$TMP_DIR/LimeTorrent.tgz"
else
    echo "Error: curl or wget is required."
    exit 1
fi

echo "Extracting..."
tar -xzf "$TMP_DIR/LimeTorrent.tgz" -C "$TMP_DIR"

echo "Installing..."
install -m 755 "$TMP_DIR/LimeTorrent" /usr/local/bin/LimeTorrent

echo
echo "✅ LimeTorrent installed successfully!"
echo

#!/usr/bin/env bash
set -euo pipefail

# Deteksi apakah dijalankan via pipe
if [[ ! -t 0 ]]; then
    NON_INTERACTIVE=true
else
    NON_INTERACTIVE=false
fi

REPO_URL="https://github.com/Limenime/LimeTorrent/releases/latest/download"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="LimeTorrent"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"

# App data directory
APP_DATA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/limetorrent"
APP_DATA_DIR_LEGACY="$HOME/.limetorrent"

# Warna (disable jika non-interactive)
if [[ "$NON_INTERACTIVE" == true ]]; then
    RED=''; GREEN=''; YELLOW=''; NC=''
else
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
fi

error_exit() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}WARNING: $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${GREEN}➜ $1${NC}"; }

show_help() {
    cat << EOF
LimeTorrent Installer Script

Usage:
  curl <url>/install.sh | sudo bash                    # Install
  curl <url>/install.sh | sudo bash -s -- --uninstall  # Uninstall (keep data)
  curl <url>/install.sh | sudo bash -s -- --delete-data # Reset app data only
  bash install.sh --uninstall --delete-data            # Complete uninstall

Options:
  --uninstall        Remove binary only
  --delete-data      Remove/reset app data only
  --help             Show this help

Note: For one-liner installation, parameters must use -s -- before options
EOF
    exit 0
}

# Parse arguments (untuk one-liner compatibility)
UNINSTALL_MODE=false
DELETE_DATA_MODE=false

for arg in "$@"; do
    case "$arg" in
        --uninstall) UNINSTALL_MODE=true ;;
        --delete-data) DELETE_DATA_MODE=true ;;
        --help|-h) show_help ;;
    esac
done

# Handle operations
if [[ "$UNINSTALL_MODE" == true ]] && [[ "$DELETE_DATA_MODE" == true ]]; then
    echo "Removing binary and app data..."
    rm -f "$BINARY_PATH" 2>/dev/null && success "Binary removed" || warn "Binary not found"
    rm -rf "$APP_DATA_DIR" "$APP_DATA_DIR_LEGACY" 2>/dev/null && success "App data removed" || true
    success "Complete uninstall finished!"
    exit 0
elif [[ "$UNINSTALL_MODE" == true ]]; then
    echo "Uninstalling (keeping app data)..."
    rm -f "$BINARY_PATH" 2>/dev/null && success "Binary removed" || warn "Binary not found"
    echo "App data preserved at: $APP_DATA_DIR"
    exit 0
elif [[ "$DELETE_DATA_MODE" == true ]]; then
    echo "Resetting app data (factory reset)..."
    rm -rf "$APP_DATA_DIR" "$APP_DATA_DIR_LEGACY" 2>/dev/null
    success "App data reset! Next run will be fresh."
    exit 0
fi

# === INSTALLATION ===
echo "=== LimeTorrent Installer ==="

# Deteksi arsitektur
case "$(uname -m)" in
    x86_64) FILE="LimeTorrent-linux-amd64.tgz" ;;
    aarch64|arm64) FILE="LimeTorrent-linux-arm64.tgz" ;;
    *) error_exit "Unsupported architecture: $(uname -m)" ;;
esac

# Create temp dir
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Download
echo "Downloading $FILE..."
if command -v curl >/dev/null; then
    curl -fsSL --retry 3 "$REPO_URL/$FILE" -o "$TMP_DIR/LimeTorrent.tgz" || error_exit "Download failed"
elif command -v wget >/dev/null; then
    wget -q --tries=3 "$REPO_URL/$FILE" -O "$TMP_DIR/LimeTorrent.tgz" || error_exit "Download failed"
else
    error_exit "curl or wget required"
fi

# Extract
tar -xzf "$TMP_DIR/LimeTorrent.tgz" -C "$TMP_DIR" || error_exit "Extract failed"
[[ -f "$TMP_DIR/LimeTorrent" ]] || error_exit "Binary not found in archive"

# Backup if exists (for rollback)
BACKUP_FILE=""
if [[ -f "$BINARY_PATH" ]]; then
    BACKUP_FILE="/tmp/LimeTorrent.bak.$(date +%s)"
    cp "$BINARY_PATH" "$BACKUP_FILE"
fi

# Install
install -m 755 "$TMP_DIR/LimeTorrent" "$BINARY_PATH" || {
    [[ -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]] && install -m 755 "$BACKUP_FILE" "$BINARY_PATH" 2>/dev/null
    error_exit "Installation failed"
}

# Cleanup backup on success
rm -f "$BACKUP_FILE"

success "LimeTorrent installed successfully"
echo ""
echo "🔄 To reset: curl <url>/install.sh | sudo bash -s -- --delete-data"
echo "🗑️  To uninstall: curl <url>/install.sh | sudo bash -s -- --uninstall"

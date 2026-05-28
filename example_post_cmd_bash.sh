#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# LimeTorrent — Post-Download Logger (Bash)
# Set via: --post-cmd "/path/to/postcmd_log.sh"
#       or: POST /postcmd/global {"command": "/path/to/postcmd_log.sh"}
# ─────────────────────────────────────────────────────────────────

LOG_FILE="${HOME}/.limetorrent/logs/download_history.log"
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
SEPARATOR="────────────────────────────────────────"

{
    echo "$SEPARATOR"
    echo "  Completed : $TIMESTAMP"
    echo "  Name      : $TORRENT_NAME"
    echo "  Hash      : $TORRENT_HASH"
    echo "  Location  : $TORRENT_SAVE_PATH"
    echo "  Total     : $TORRENT_SIZE bytes"
    echo "  File count: $TORRENT_FILE_COUNT"
    echo "  Api Key   : $LIME_API_KEY"
    echo ""

    # ── Loop per-file using underscore-indexed env vars ──────────
    # Accessible directly: $TORRENT_LISTFILE_NAME_0, $TORRENT_LISTFILE_PATH_0, etc.
    for (( i=0; i<TORRENT_FILE_COUNT; i++ )); do
        name_var="TORRENT_LISTFILE_NAME_${i}"
        path_var="TORRENT_LISTFILE_PATH_${i}"
        size_var="TORRENT_LISTFILE_SIZE_${i}"

        echo "  [$i] Name : ${!name_var}"
        echo "       Path : ${!path_var}"
        echo "       Size : ${!size_var} bytes"
    done

    echo ""
} >> "$LOG_FILE"

echo "[postcmd] Log written to: $LOG_FILE"

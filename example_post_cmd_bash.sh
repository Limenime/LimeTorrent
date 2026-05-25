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
    echo ""

    # ── Loop per-file using the four env vars ────────────
    # Because variable names contain "[i]", access using ${!var} syntax
    for (( i=0; i<TORRENT_FILE_COUNT; i++ )); do
        name_var="TORRENT_LISTFILE_NAME[$i]"
        path_var="TORRENT_LISTFILE_PATH[$i]"
        size_var="TORRENT_LISTFILE_SIZE[$i]"

        fname="${!name_var}"
        fpath="${!path_var}"
        fsize="${!size_var}"

        echo "  [$i] Name : $fname"
        echo "       Path : $fpath"
        echo "       Size : $fsize bytes"
    done

    echo ""
} >> "$LOG_FILE"

echo "[postcmd] Log written to: $LOG_FILE"

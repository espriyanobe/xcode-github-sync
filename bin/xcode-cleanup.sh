#!/usr/bin/env bash
# Purge les caches Xcode régénérables pour libérer de l'espace.
# Ne touche pas : Archives, Provisioning Profiles, code source.

set -euo pipefail

LOG="$HOME/Library/Logs/xcode-github-sync.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
freed=0

log() { echo "[$TIMESTAMP] $*" | tee -a "$LOG"; }

clean_dir() {
    local path="$1" label="$2"
    if [ -d "$path" ]; then
        local size
        size=$(du -sm "$path" 2>/dev/null | awk '{print $1}')
        rm -rf "${path:?}/"* 2>/dev/null || true
        freed=$((freed + size))
        log "Nettoyé : $label (${size} MB)"
    fi
}

log "=== Début nettoyage Xcode ==="

clean_dir "$HOME/Library/Developer/Xcode/UserData/Previews" "SwiftUI Previews"
clean_dir "$HOME/Library/Developer/Xcode/DerivedData"       "Derived Data"
clean_dir "$HOME/Library/Caches/com.apple.dt.Xcode"         "Xcode Caches"

if [ -d "$HOME/Library/Developer/Xcode/DeviceLogs" ]; then
    find "$HOME/Library/Developer/Xcode/DeviceLogs" \
        -name "*.logarchive" -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    log "Nettoyé : DeviceLogs > 30 jours"
fi

if command -v xcrun &>/dev/null; then
    xcrun simctl delete unavailable 2>/dev/null && log "Simulateurs unavailable supprimés" || true
fi

log "=== Fin nettoyage (~${freed} MB libérés) ==="
echo "Nettoyage terminé. ~${freed} MB libérés. Log : $LOG"

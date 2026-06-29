#!/usr/bin/env bash
# Désinstalle xcode-github-sync complètement.

set -euo pipefail

CONFIG_FILE="$HOME/.config/xcode-github-sync/config"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
ok()  { echo -e "${GREEN}✓${NC} $*"; }
err() { echo -e "${RED}✗${NC} $*"; }

echo ""
echo "Désinstallation de xcode-github-sync"
read -rp "Confirmer ? Cela supprime les scripts et les tâches planifiées. [o/N] : " confirm
[[ "$confirm" =~ ^[oO]$ ]] || { echo "Annulé."; exit 0; }

# Lire le nom d'utilisateur pour trouver les bons labels
GITHUB_USER=""
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Décharger et supprimer les LaunchAgents
for label in "com.$GITHUB_USER.github-sync" "com.$GITHUB_USER.xcode-cleanup"; do
    plist="$HOME/Library/LaunchAgents/$label.plist"
    if [ -f "$plist" ]; then
        launchctl unload "$plist" 2>/dev/null || true
        rm -f "$plist"
        ok "LaunchAgent supprimé : $label"
    fi
done

# Supprimer les scripts
for script in add-to-github.sh github-sync.sh xcode-cleanup.sh; do
    rm -f "$HOME/.local/bin/$script" && ok "Script supprimé : $script"
done

# Supprimer la config
rm -rf "$HOME/.config/xcode-github-sync"
ok "Config supprimée"

echo ""
ok "Désinstallation terminée. Tes projets et repos GitHub sont intacts."
echo ""

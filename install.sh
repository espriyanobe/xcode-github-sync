#!/usr/bin/env bash
# xcode-github-sync — Installer
# https://github.com/espriyanobe/xcode-github-sync

set -euo pipefail

CONFIG_DIR="$HOME/.config/xcode-github-sync"
CONFIG_FILE="$CONFIG_DIR/config"
PROJECTS_FILE="$CONFIG_DIR/projects"
BIN_DIR="$HOME/.local/bin"
AGENTS_DIR="$HOME/Library/LaunchAgents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
info() { echo -e "${BLUE}→${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*"; exit 1; }
ask()  { echo -e "${BOLD}$*${NC}"; }

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}   xcode-github-sync — Installation          ${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 1. Config utilisateur ────────────────────────────────────────────────────

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    warn "Config existante détectée pour $GITHUB_USER."
    read -rp "Réinstaller et écraser ? [o/N] : " overwrite
    [[ "$overwrite" =~ ^[oO]$ ]] || { echo "Installation annulée."; exit 0; }
fi

ask "Nom d'utilisateur GitHub :"
read -rp "→ " GITHUB_USER
[[ -z "$GITHUB_USER" ]] && err "Nom d'utilisateur requis"

ask "Adresse email (pour les commits git) :"
read -rp "→ " GIT_EMAIL
[[ -z "$GIT_EMAIL" ]] && err "Email requis"

ask "Ton prénom / pseudo pour les commits :"
read -rp "→ " GIT_NAME
[[ -z "$GIT_NAME" ]] && err "Nom requis"

ask "Heure du sync automatique ? [défaut : 20] :"
read -rp "→ " SYNC_HOUR
SYNC_HOUR="${SYNC_HOUR:-20}"

# ── 2. Sauvegarder la config ─────────────────────────────────────────────────

mkdir -p "$CONFIG_DIR" && chmod 700 "$CONFIG_DIR"
cat > "$CONFIG_FILE" << EOF
GITHUB_USER="$GITHUB_USER"
GIT_EMAIL="$GIT_EMAIL"
GIT_NAME="$GIT_NAME"
SYNC_HOUR="$SYNC_HOUR"
EOF
chmod 600 "$CONFIG_FILE"
ok "Config sauvegardée → $CONFIG_FILE"

touch "$PROJECTS_FILE"
ok "Fichier projets → $PROJECTS_FILE"

# ── 3. Clé SSH ───────────────────────────────────────────────────────────────

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    info "Génération d'une clé SSH ed25519..."
    ssh-keygen -t ed25519 -C "$GITHUB_USER@mac" -f "$HOME/.ssh/id_ed25519" -N ""
    ok "Clé SSH générée"
else
    ok "Clé SSH existante trouvée"
fi

ssh-keyscan -t ed25519,rsa github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
ok "github.com ajouté aux hôtes connus"

# ── 4. Installer les scripts ─────────────────────────────────────────────────

mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/bin/add-to-github.sh" "$BIN_DIR/add-to-github.sh"
cp "$SCRIPT_DIR/bin/github-sync.sh"   "$BIN_DIR/github-sync.sh"
cp "$SCRIPT_DIR/bin/xcode-cleanup.sh" "$BIN_DIR/xcode-cleanup.sh"
chmod +x "$BIN_DIR/add-to-github.sh" "$BIN_DIR/github-sync.sh" "$BIN_DIR/xcode-cleanup.sh"
ok "Scripts installés dans $BIN_DIR"

# ── 5. LaunchAgents ──────────────────────────────────────────────────────────

LABEL_SYNC="com.$GITHUB_USER.github-sync"
LABEL_CLEAN="com.$GITHUB_USER.xcode-cleanup"

# Décharger les anciens si présents
launchctl unload "$AGENTS_DIR/$LABEL_SYNC.plist" 2>/dev/null || true
launchctl unload "$AGENTS_DIR/$LABEL_CLEAN.plist" 2>/dev/null || true

sed "s|{{BIN_DIR}}|$BIN_DIR|g; s|{{LABEL}}|$LABEL_SYNC|g; s|{{HOUR}}|$SYNC_HOUR|g" \
    "$SCRIPT_DIR/launchagents/sync.plist.template" \
    > "$AGENTS_DIR/$LABEL_SYNC.plist"

sed "s|{{BIN_DIR}}|$BIN_DIR|g; s|{{LABEL}}|$LABEL_CLEAN|g" \
    "$SCRIPT_DIR/launchagents/cleanup.plist.template" \
    > "$AGENTS_DIR/$LABEL_CLEAN.plist"

launchctl load "$AGENTS_DIR/$LABEL_SYNC.plist"
launchctl load "$AGENTS_DIR/$LABEL_CLEAN.plist"
ok "LaunchAgents activés (sync à ${SYNC_HOUR}h, nettoyage dimanche 2h)"

# ── 6. Instructions finales ───────────────────────────────────────────────────

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}   Installation terminée !${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Action requise — ajoute cette clé SSH sur GitHub :${NC}"
echo -e "${BLUE}https://github.com/settings/keys → New SSH key${NC}"
echo ""
echo -e "${YELLOW}$(cat "$HOME/.ssh/id_ed25519.pub")${NC}"
echo ""
echo -e "${BOLD}Ensuite, ajoute ton premier projet :${NC}"
echo -e "  ${GREEN}add-to-github.sh${NC}"
echo ""
echo -e "${BOLD}Commandes disponibles :${NC}"
echo "  add-to-github.sh    — Ajouter un projet à GitHub"
echo "  github-sync.sh      — Forcer un sync maintenant"
echo "  xcode-cleanup.sh    — Nettoyer les caches Xcode"
echo ""

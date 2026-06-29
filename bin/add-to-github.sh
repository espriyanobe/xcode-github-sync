#!/usr/bin/env bash
# Ajoute n'importe quel dossier local à GitHub et à l'auto-sync.

set -euo pipefail

CONFIG_FILE="$HOME/.config/xcode-github-sync/config"
PROJECTS_FILE="$HOME/.config/xcode-github-sync/projects"
TOKEN_FILE="$HOME/.config/xcode-github-sync/token"

[ -f "$CONFIG_FILE" ] || { echo "Config introuvable. Lance d'abord install.sh"; exit 1; }
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
info() { echo -e "${BLUE}→${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*"; exit 1; }

GITIGNORE_TEMPLATES=(
    "Xcode / Swift"
    "Node / JavaScript"
    "Python"
    "Basique (macOS seulement)"
)

GITIGNORE_XCODE='# Xcode
build/
DerivedData/
*.xcuserstate
xcuserdata/
*.dSYM/
.build/
.swiftpm/xcworkspace
*.p12
*.mobileprovision'

GITIGNORE_NODE='node_modules/
dist/
.env
.env.local
npm-debug.log*
yarn-error.log*
.pnpm-debug.log*'

GITIGNORE_PYTHON='__pycache__/
*.pyc
*.pyo
.venv/
venv/
.env
*.egg-info/
dist/
build/'

GITIGNORE_BASIC=''

# ── Token ─────────────────────────────────────────────────────────────────────

check_token() {
    if [ ! -f "$TOKEN_FILE" ] || [ ! -s "$TOKEN_FILE" ]; then
        echo ""
        warn "Token GitHub requis pour créer le repo automatiquement."
        echo ""
        echo "  1. Va sur https://github.com/settings/tokens/new"
        echo "  2. Note : 'xcode-github-sync'"
        echo "  3. Expiration : No expiration"
        echo "  4. Scope : coche uniquement 'repo'"
        echo "  5. Clique Generate token → copie le token (ghp_...)"
        echo ""
        read -rp "Colle ton token : " token
        echo "$token" > "$TOKEN_FILE" && chmod 600 "$TOKEN_FILE"
        ok "Token enregistré"
    fi
    GITHUB_TOKEN=$(cat "$TOKEN_FILE")
}

# ── Choisir le dossier ────────────────────────────────────────────────────────

pick_folder() {
    echo ""
    echo -e "${BOLD}Dossiers disponibles :${NC}"
    echo ""

    mapfile -t FOLDERS < <(
        find ~/Desktop ~/Documents ~/Developer ~/Projects ~/Downloads 2>/dev/null \
            -maxdepth 3 -mindepth 1 -type d \
            ! -path "*/.git/*" \
            ! -path "*/DerivedData/*" \
            ! -path "*/node_modules/*" \
            ! -path "*/__pycache__/*" \
            ! -path "*/.Trash/*" \
            ! -name ".*" \
            2>/dev/null | sort -u
    )

    for i in "${!FOLDERS[@]}"; do
        local tag=""
        [ -d "${FOLDERS[$i]}/.git" ] && tag=" ${GREEN}[git]${NC}"
        grep -qxF "${FOLDERS[$i]}" "$PROJECTS_FILE" 2>/dev/null && tag=" ${YELLOW}[déjà sync]${NC}"
        echo -e "  $((i+1)). $(basename "${FOLDERS[$i]}")  ${BLUE}${FOLDERS[$i]}${NC}$tag"
    done

    echo "  $((${#FOLDERS[@]}+1)). Entrer un chemin manuellement"
    echo ""
    read -rp "Choix : " choice

    if [ "$choice" -eq "$((${#FOLDERS[@]}+1))" ] 2>/dev/null; then
        read -rp "Chemin complet : " PROJECT_PATH
        PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"
    else
        PROJECT_PATH="${FOLDERS[$((choice-1))]}"
    fi

    [ -d "$PROJECT_PATH" ] || err "Dossier introuvable : $PROJECT_PATH"
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    ok "Dossier : $PROJECT_NAME"
}

# ── Git init ──────────────────────────────────────────────────────────────────

pick_gitignore() {
    if [ -f "$PROJECT_PATH/.gitignore" ]; then
        ok ".gitignore existant conservé"
        GITIGNORE_CONTENT=""
        return
    fi

    echo ""
    echo -e "${BOLD}Quel type de projet ?${NC}"
    for i in "${!GITIGNORE_TEMPLATES[@]}"; do
        echo "  $((i+1)). ${GITIGNORE_TEMPLATES[$i]}"
    done
    echo ""
    read -rp "Choix [1-${#GITIGNORE_TEMPLATES[@]}] : " tpl_choice

    case "$tpl_choice" in
        1) GITIGNORE_CONTENT="$GITIGNORE_XCODE"  ;;
        2) GITIGNORE_CONTENT="$GITIGNORE_NODE"   ;;
        3) GITIGNORE_CONTENT="$GITIGNORE_PYTHON" ;;
        *) GITIGNORE_CONTENT="$GITIGNORE_BASIC"  ;;
    esac

    # .DS_Store toujours ignoré
    GITIGNORE_CONTENT="$GITIGNORE_CONTENT
# macOS
.DS_Store
*.icloud"
}

setup_git() {
    cd "$PROJECT_PATH"

    if [ ! -d ".git" ]; then
        git init -b main
        ok "Git initialisé"
    else
        ok "Git déjà initialisé"
    fi

    pick_gitignore

    if [ -n "$GITIGNORE_CONTENT" ]; then
        echo "$GITIGNORE_CONTENT" > .gitignore
        ok ".gitignore créé"
    fi

    git add .
    if ! git diff --cached --quiet 2>/dev/null || [ "$(git rev-list --count HEAD 2>/dev/null || echo 0)" -eq 0 ]; then
        git commit -m "Initial commit" \
            --author="$GIT_NAME <$GIT_EMAIL>" 2>/dev/null || true
        ok "Commit initial"
    else
        ok "Rien à commiter"
    fi
}

# ── Créer repo GitHub ─────────────────────────────────────────────────────────

create_repo() {
    info "Création du repo '$PROJECT_NAME' sur GitHub..."

    local http_code
    http_code=$(curl -s -o /tmp/xgs_response.json -w "%{http_code}" \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/user/repos \
        -d "{\"name\":\"$PROJECT_NAME\",\"private\":true,\"auto_init\":false}")

    case "$http_code" in
        201) ok "Repo créé (private) → github.com/$GITHUB_USER/$PROJECT_NAME" ;;
        422) warn "Repo '$PROJECT_NAME' existe déjà — on continue" ;;
        401) err "Token invalide. Supprime $TOKEN_FILE et relance." ;;
        *)   err "Erreur API GitHub ($http_code) : $(cat /tmp/xgs_response.json)" ;;
    esac
}

# ── Push ──────────────────────────────────────────────────────────────────────

push() {
    cd "$PROJECT_PATH"

    if ! git remote get-url origin &>/dev/null; then
        git remote add origin "git@github.com:$GITHUB_USER/$PROJECT_NAME.git"
        ok "Remote ajouté"
    fi

    info "Push vers GitHub..."
    git push -u origin main 2>&1 || err "Push échoué. Vérifie ta clé SSH sur github.com/settings/keys"
    ok "Push réussi"
}

# ── Ajouter à la liste de sync ────────────────────────────────────────────────

add_to_sync() {
    if grep -qxF "$PROJECT_PATH" "$PROJECTS_FILE" 2>/dev/null; then
        ok "Déjà dans la liste de sync"
    else
        echo "$PROJECT_PATH" >> "$PROJECTS_FILE"
        ok "Ajouté au sync quotidien"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}   Add to GitHub                              ${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_token
pick_folder
setup_git
create_repo
push
add_to_sync

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
ok "Terminé ! '$PROJECT_NAME' sync chaque soir à ${SYNC_HOUR}h."
echo -e "   ${BLUE}https://github.com/$GITHUB_USER/$PROJECT_NAME${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

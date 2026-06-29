#!/usr/bin/env bash
# Synchronise tous les projets listés vers GitHub.
# Lancé automatiquement par launchd — peut aussi être lancé manuellement.

set -euo pipefail

CONFIG_FILE="$HOME/.config/xcode-github-sync/config"
PROJECTS_FILE="$HOME/.config/xcode-github-sync/projects"
LOG="$HOME/Library/Logs/xcode-github-sync.log"

[ -f "$CONFIG_FILE" ] || { echo "Config introuvable. Lance d'abord install.sh"; exit 1; }
source "$CONFIG_FILE"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
log() { echo "[$TIMESTAMP] $*" | tee -a "$LOG"; }

push_project() {
    local path="$1"
    local name
    name=$(basename "$path")

    log "=== $name ==="

    [ -d "$path/.git" ] || { log "SKIP : pas de .git dans $path"; return; }

    cd "$path"

    if ! git remote get-url origin &>/dev/null; then
        log "SKIP : aucun remote configuré — lance add-to-github.sh"
        return
    fi

    if ! git diff --quiet || ! git diff --cached --quiet || \
       [ -n "$(git ls-files --others --exclude-standard)" ]; then
        git add .
        git commit -m "Auto-sync : $(date '+%Y-%m-%d %H:%M')" \
            --author="$GIT_NAME <$GIT_EMAIL>" 2>/dev/null || true
        log "Commit créé"
    else
        log "Aucun changement"
    fi

    if git push origin main 2>&1 | tee -a "$LOG"; then
        log "Push réussi : $name"
    else
        log "ERREUR push $name"
    fi
}

log "=== Début sync ==="

[ -f "$PROJECTS_FILE" ] || { log "Aucun projet configuré."; exit 0; }

while IFS= read -r project || [ -n "$project" ]; do
    [[ -z "$project" || "$project" == \#* ]] && continue
    push_project "$project"
done < "$PROJECTS_FILE"

log "=== Fin sync ==="

# xcode-github-sync

> Sauvegarde automatiquement n'importe quel dossier de ton Mac sur GitHub, chaque soir, sans que tu aies à faire quoi que ce soit.

Fonctionne avec tous types de projets : Xcode/Swift, Node, Python, fichiers design, documents…

---

## Ce que ça fait concrètement

Imagine que tu travailles sur un projet. Tu fais tes modifications, tu fermes ton Mac. **À 20h chaque soir, le script se lance tout seul** en arrière-plan et envoie tous tes changements sur GitHub.

- Tu n'ouvres pas de terminal
- Tu ne tapes aucune commande
- Tu ne penses à rien

Si tu perds ton Mac, si tu le formates, ou si tu veux donner ton projet à quelqu'un : **tout est sur GitHub**, à jour, en sécurité.

En bonus, **chaque dimanche à 2h du matin**, il nettoie automatiquement les caches Xcode (SwiftUI Previews, DerivedData…) qui peuvent prendre 3 à 5 GB sans servir à rien.

---

## Prérequis

- Un Mac sous macOS 12 ou plus récent
- Un compte [GitHub](https://github.com) (gratuit)
- C'est tout — aucun logiciel supplémentaire à installer

---

## Installation — 3 étapes

### Étape 1 — Télécharger le projet

Ouvre le **Terminal** (cherche "Terminal" dans Spotlight avec `Cmd + Espace`) et colle ces deux lignes :

```bash
git clone https://github.com/espriyanobe/xcode-github-sync.git
cd xcode-github-sync && ./install.sh
```

Le script te pose 4 questions :
- Ton nom d'utilisateur GitHub (ex: `johndoe`)
- Ton adresse email (pour identifier tes commits)
- Ton prénom ou pseudo
- L'heure du sync quotidien (laisse vide pour garder 20h par défaut)

### Étape 2 — Ajouter ta clé SSH sur GitHub

À la fin de l'installation, le script affiche une longue ligne qui commence par `ssh-ed25519 AAAA...`

**Copie cette ligne entière**, puis :

1. Va sur [github.com/settings/keys](https://github.com/settings/keys)
2. Clique **New SSH key**
3. Titre : `Mon Mac`
4. Colle la clé
5. Clique **Add SSH key**

> C'est ce qui permet à ton Mac d'envoyer des fichiers sur GitHub sans avoir à taper un mot de passe à chaque fois.

### Étape 3 — Ajouter ton premier dossier

```bash
add-to-github.sh
```

La première fois, le script te demande un **Personal Access Token GitHub** — c'est une clé secrète qui lui permet de créer des repos automatiquement à ta place.

Pour le créer :
1. Va sur [github.com/settings/tokens/new](https://github.com/settings/tokens/new)
2. Note : `xcode-github-sync`
3. Expiration : **No expiration**
4. Coche uniquement **`repo`**
5. Clique **Generate token** → copie le code `ghp_...`

Ensuite le script te montre la liste de tes dossiers. Tu tapes le numéro du dossier que tu veux sauvegarder. Il fait tout le reste.

---

## Comment ça se passe concrètement

```
$ add-to-github.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Add to GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dossiers disponibles :

  1. MonAppli          /Users/toi/Desktop/MonAppli
  2. SiteWeb           /Users/toi/Documents/SiteWeb
  3. Stathub           /Users/toi/Desktop/Stathub  [git]
  4. Entrer un chemin manuellement

Choix : 1

Quel type de projet ?
  1. Xcode / Swift
  2. Node / JavaScript
  3. Python
  4. Basique (macOS seulement)

Choix : 1

✓ Git initialisé
✓ .gitignore créé
✓ Commit initial
✓ Repo créé (private) → github.com/toi/MonAppli
✓ Push réussi
✓ Ajouté au sync quotidien

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Terminé ! 'MonAppli' sync chaque soir à 20h.
   https://github.com/toi/MonAppli
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Commandes utiles

```bash
# Ajouter un nouveau dossier à GitHub
add-to-github.sh

# Forcer un sync maintenant sans attendre 20h
github-sync.sh

# Nettoyer les caches Xcode maintenant
xcode-cleanup.sh

# Voir l'historique des syncs
cat ~/Library/Logs/xcode-github-sync.log

# Vérifier que la synchro automatique tourne bien
launchctl list | grep github-sync
```

---

## Désinstaller

```bash
cd xcode-github-sync
./uninstall.sh
```

Supprime les scripts et les tâches planifiées. Tes dossiers et repos GitHub ne sont pas touchés.

---

## Pourquoi c'est fiable

- **SSH** : la clé d'authentification ne expire jamais, zéro maintenance
- **launchd** : le gestionnaire de tâches natif de macOS, redémarre avec le Mac
- **Pas de dépendances** : bash pur, rien à installer, rien à mettre à jour
- **Open source** : le code est visible, modifiable, gratuit pour toujours

---

## License

MIT — libre d'utilisation, de partage et de modification.

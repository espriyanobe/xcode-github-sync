# xcode-github-sync

> Transfère et sauvegarde automatiquement **n'importe quel dossier** de ton Mac sur GitHub — code source, sites web, applications, documents — sans manipulation manuelle.

Tu travailles sur un site web, une app, un script, un projet perso ? Lance une commande, choisis ton dossier, et à partir de là **tout se sauvegarde tout seul chaque soir sur GitHub**.

Une fois ton projet en sécurité sur GitHub, **tu peux supprimer ta copie locale pour libérer de l'espace sur ton Mac**. Si tu en as besoin à nouveau, tu le retélécharges en une commande. C'est particulièrement utile pour les projets Xcode qui peuvent peser plusieurs gigaoctets à cause des caches générés automatiquement.

Aucun besoin de connaître git. Aucun logiciel supplémentaire. Ça fonctionne dès l'installation.

---

## Pour qui ?

- Tu fais du développement web (HTML, CSS, JavaScript, React, Vue…)
- Tu codes des apps iOS, Android, ou macOS
- Tu as des scripts Python, Ruby, ou autre
- Tu veux juste garder un dossier en sécurité en ligne
- Tu veux partager ton code source sur GitHub

**Xcode n'est pas requis.** Le nettoyage de caches Xcode est une fonctionnalité bonus qui s'active seulement si Xcode est installé.

---

## Ce que ça fait concrètement

Tu travailles sur tes projets normalement. **Chaque soir à 20h**, le script se lance tout seul en arrière-plan, enregistre tous tes changements et les envoie sur GitHub.

- Tu n'ouvres pas de terminal
- Tu ne tapes aucune commande
- Tu ne penses à rien

Si tu perds ton Mac, si tu le formates, ou si tu veux partager ton code : **tout est sur GitHub**, à jour, accessible depuis n'importe où.

### Libérer de l'espace sur ton Mac

C'est l'un des usages les plus puissants de cet outil. Une fois un projet envoyé sur GitHub, **tu peux supprimer le dossier local** pour récupérer de l'espace disque. Quand tu en as besoin, tu le retélécharges :

```bash
git clone git@github.com:tonusername/tonprojet.git
```

Les projets Xcode sont particulièrement gourmands : entre les caches, les previews SwiftUI et les fichiers de build, un seul projet peut occuper **5 à 10 GB**. En les gardant sur GitHub plutôt que sur ton Mac, tu gardes ton disque libre.

### Bonus si tu as Xcode

Chaque dimanche à 2h du matin, le script nettoie automatiquement les caches Xcode (SwiftUI Previews, DerivedData…) qui peuvent prendre 3 à 5 GB sans rien apporter.

---

## Prérequis

- Un Mac sous macOS 12 ou plus récent
- Un compte [GitHub](https://github.com) (gratuit)
- C'est tout — Xcode, Homebrew, Node.js ne sont pas nécessaires

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

> C'est ce qui permet à ton Mac d'envoyer des fichiers sur GitHub sans mot de passe à chaque fois.

### Étape 3 — Ajouter ton premier dossier

```bash
add-to-github.sh
```

La première fois, le script te demande un **Personal Access Token GitHub** — une clé qui lui permet de créer des repos automatiquement.

Pour le créer :
1. Va sur [github.com/settings/tokens/new](https://github.com/settings/tokens/new)
2. Note : `xcode-github-sync`
3. Expiration : **No expiration**
4. Coche uniquement **`repo`**
5. Clique **Generate token** → copie le code `ghp_...`

Ensuite le script affiche la liste de tes dossiers. Tu choisis. Il fait tout le reste.

---

## Comment ça se passe concrètement

```
$ add-to-github.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Add to GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dossiers disponibles :

  1. MonSiteWeb        /Users/toi/Desktop/MonSiteWeb
  2. AppReact          /Users/toi/Documents/AppReact
  3. MonAppIOS         /Users/toi/Desktop/MonAppIOS
  4. Entrer un chemin manuellement

Choix : 1

Quel type de projet ?
  1. Xcode / Swift
  2. Node / JavaScript
  3. Python
  4. Basique (macOS seulement)

Choix : 2

✓ Git initialisé
✓ .gitignore créé
✓ Commit initial
✓ Repo créé (private) → github.com/toi/MonSiteWeb
✓ Push réussi
✓ Ajouté au sync quotidien

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Terminé ! 'MonSiteWeb' sync chaque soir à 20h.
   https://github.com/toi/MonSiteWeb
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Commandes utiles

```bash
# Ajouter un nouveau dossier à GitHub
add-to-github.sh

# Forcer un sync maintenant sans attendre 20h
github-sync.sh

# Nettoyer les caches Xcode (si Xcode est installé)
xcode-cleanup.sh

# Voir l'historique des syncs
cat ~/Library/Logs/xcode-github-sync.log

# Vérifier que la synchro automatique tourne bien
launchctl list | grep github-sync
```

---

## Types de projets supportés

| Type | .gitignore inclus | Exemples |
|---|---|---|
| Xcode / Swift | ✅ | Apps iOS, macOS, visionOS |
| Node / JavaScript | ✅ | Sites web, React, Vue, Next.js |
| Python | ✅ | Scripts, Flask, Django, ML |
| Basique | ✅ | N'importe quel autre dossier |
| Existant | — | Conserve ton .gitignore actuel |

---

## Désinstaller

```bash
cd xcode-github-sync
./uninstall.sh
```

Supprime les scripts et les tâches planifiées. Tes dossiers et repos GitHub ne sont pas touchés.

---

## Pourquoi c'est fiable

- **SSH** : authentification qui n'expire jamais, zéro maintenance
- **launchd** : gestionnaire de tâches natif macOS, redémarre avec le Mac
- **Pas de dépendances** : bash pur, rien à installer, rien à mettre à jour
- **Open source** : code visible, modifiable, gratuit pour toujours

---

## License

MIT — libre d'utilisation, de partage et de modification.

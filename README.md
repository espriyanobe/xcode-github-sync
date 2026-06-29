# xcode-github-sync

Automatically back up your Xcode projects to GitHub and keep your Mac clean — no manual effort, no tokens to renew, runs silently in the background.

**Made for Mac developers who want their projects safe on GitHub without thinking about it.**

---

## What it does

| Feature | Detail |
|---|---|
| **Auto-push** | Commits and pushes your projects to GitHub every evening |
| **Auto-cleanup** | Purges SwiftUI Previews, Derived Data, and Xcode caches every Sunday |
| **One command** to add a project | Interactive folder picker, repo created automatically |
| **No dependencies** | Pure bash + macOS launchd — no Homebrew, no Node, no Python |
| **Never expires** | SSH key authentication — no token renewal |

---

## Requirements

- macOS 12+
- Xcode installed
- A [GitHub account](https://github.com)

---

## Installation

```bash
git clone https://github.com/espriyanobe/xcode-github-sync.git
cd xcode-github-sync
chmod +x install.sh
./install.sh
```

The installer will ask for:
- Your GitHub username
- Your email (for git commits)
- Your name (for git commits)
- What time to run the daily sync (default: 8 PM)

At the end, it shows your SSH public key — **copy it and add it on [github.com/settings/keys](https://github.com/settings/keys)**.

---

## Adding a project

```bash
add-to-github.sh
```

First time only: it asks for a [GitHub Personal Access Token](https://github.com/settings/tokens/new) (scope: `repo`, no expiration) to create repos automatically.

The script then:
1. Shows all your project folders — pick one
2. Initializes git + creates a proper Xcode `.gitignore`
3. Creates a **private** repo on GitHub
4. Pushes your code
5. Adds the project to the nightly sync list

---

## Daily commands

```bash
# Force a sync right now
github-sync.sh

# Clean Xcode caches right now (~3-5 GB freed)
xcode-cleanup.sh

# Check that background tasks are running
launchctl list | grep github-sync

# Watch the logs
tail -f ~/Library/Logs/xcode-github-sync.log
```

---

## What gets cleaned (every Sunday at 2 AM)

| Folder | What it is | Safe to delete? |
|---|---|---|
| `UserData/Previews` | SwiftUI preview cache | ✅ Yes — regenerated on demand |
| `DerivedData` | Build artifacts | ✅ Yes — regenerated on build |
| `Caches/com.apple.dt.Xcode` | Xcode cache | ✅ Yes |
| `DeviceLogs` (> 30 days) | Old debug logs | ✅ Yes |
| Unavailable simulators | Old iOS runtimes | ✅ Yes |

**Never touched:** your source code, Archives, Provisioning Profiles, SSH keys.

---

## How it works

```
macOS launchd
├── Every day at 8 PM  →  github-sync.sh
│                            reads ~/.config/xcode-github-sync/projects
│                            git add . && git commit && git push (SSH)
│
└── Every Sunday 2 AM  →  xcode-cleanup.sh
                             deletes regenerable Xcode cache folders
```

Authentication uses your SSH key — it never expires and requires no interaction.

---

## File structure

```
~/.config/xcode-github-sync/
├── config      # GitHub username, email, sync hour
├── projects    # One project path per line
└── token       # GitHub PAT (chmod 600, used only to create repos)

~/.local/bin/
├── add-to-github.sh
├── github-sync.sh
└── xcode-cleanup.sh

~/Library/LaunchAgents/
├── com.<username>.github-sync.plist
└── com.<username>.xcode-cleanup.plist
```

---

## Uninstall

```bash
./uninstall.sh
```

Removes scripts, LaunchAgents, and config. Your projects and GitHub repos are untouched.

---

## License

MIT — free to use, share, and modify.

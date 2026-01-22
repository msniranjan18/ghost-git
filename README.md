# ghost-git
The developer's "Invisibility Cloak" for shared workstations.
GhostGit is a lightweight, Docker-based wrapper that allows you to perform Git operations on a shared machine without ever touching the host's global Git configuration or SSH keys. It ensures every commit is in your name and every push uses your keys, leaving zero footprint when you close the terminal.

### The Problem
Working on shared laptops (e.g., pair programming, office "hot desks") often leads to:

 - Accidentally committing as the previous user.
 - Having to overwrite git config --global constantly.
 - Security risks of leaving your SSH keys in the default ~/.ssh folder.


### Features
 
 - *Total Isolation:* Runs Git inside an ephemeral Docker container.
 - *Identity Guard:* Automatically mounts your personal .gitconfig and .ssh keys.
 - *Auto-Cleanup:* SSH agents are killed automatically when you exit the terminal.
 - *Zero Pollution:* Does not modify the host's global Git settings.

### Setup
#### 1. Clone & Initialize

```Bash
git clone https://github.com/your-username/ghost-git.git
cd ghost-git
chmod +x scripts/*.sh
./scripts/setup.sh
```
During setup, you will be asked for your name and email. These will be stored locally in .mygit-identity/.gitconfig.

#### 2. Add your SSH Keys
Copy your private keys into the hidden identity folder:

```Bash
cp ~/.ssh/id_ed25519 .mygit-identity/.ssh/
```

###  Usage
#### Standard Mode
For quick commands (will ask for SSH passphrase if applicable):

```Bash
mygit commit -m "feat: adding clean logic"
mygit push
```

#### Secure Session Mode (SSH Agent)
For long work sessions where you don't want to type your passphrase repeatedly. 
This starts a "Stealth Agent" that kills itself when the window is closed:

```Bash
source scripts/session.sh
mygit-ssh push
```

### Security
- *Read-Only:* The container mounts your identity folder as readonly.
- *No Persistence:* The container is destroyed (--rm) immediately after the command executes.
- *Trap Exit:* The session.sh script uses a shell trap to ensure ssh-agent is terminated on logout.

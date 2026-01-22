#!/bin/bash

# --- Configuration ---
# Get the absolute path of the ghost-git root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDENTITY_DIR="$REPO_ROOT/.mygit-identity"
ALIAS_NAME="mygit"
GIT_IMAGE="alpine/git"

echo "Starting GhostGit local setup..."

# 1. Create Identity Directory inside the repo
if [ ! -d "$IDENTITY_DIR" ]; then
    mkdir -p "$IDENTITY_DIR/.ssh"
    echo "Created $IDENTITY_DIR"
else
    echo "Identity directory already exists."
fi

# 2. Check for .gitconfig inside the repo
if [ ! -f "$IDENTITY_DIR/.gitconfig" ]; then
    echo "No .gitconfig found. Let's create one for your container:"
    read -p "Enter your Git Name: " git_name
    read -p "Enter your Git Email: " git_email
    
    cat <<EOF > "$IDENTITY_DIR/.gitconfig"
[user]
    name = $git_name
    email = $git_email
[color]
    ui = auto
[safe]
    directory = /git
EOF
    echo "Created .gitconfig"
fi

# 3. Instruction for SSH Keys
if [ -z "$(ls -A $IDENTITY_DIR/.ssh)" ]; then
    echo "Action Required: Copy your private SSH keys to the local folder:"
    echo "    Command: cp ~/.ssh/id_rsa $IDENTITY_DIR/.ssh/"
    echo "    For new key generation:"
    echo "    Command: ssh-keygen -t ed25519 -f $IDENTITY_DIR/.ssh/id_ed25519 -C <your-git-email-id>"
    echo "    Add this key to github: GitHub → Profile → Settings → SSH and GPG keys → New SSH key → Paste id_ed25519.pub key"
fi

# 4. Define the Alias Logic (Using the local path)
# We add -e GIT_SSH_COMMAND to bypass the 'known_hosts' write error
# We add --user 0:0 to ensure the container can read the mounted keys
DOCKER_RUN_CMD='docker run --rm -it --user 0:0 -v "$(pwd):/git" -v "/Users/manvendra/WORK-DIR/POC/ghost-git/.mygit-identity/.gitconfig:/root/.gitconfig:ro" -v "/Users/manvendra/WORK-DIR/POC/ghost-git/.mygit-identity/.ssh:/root/.ssh:ro" -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" alpine/git'

# 5. Detect Shell and Add Alias
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Escape the command for the grep and append
    if ! grep -q "alias $ALIAS_NAME=" "$SHELL_RC"; then
        echo "alias $ALIAS_NAME='$DOCKER_RUN_CMD'" >> "$SHELL_RC"
        echo "Added alias '$ALIAS_NAME' to $SHELL_RC"
        echo "Please run: source $SHELL_RC"
    else
        echo "Alias '$ALIAS_NAME' already exists in $SHELL_RC (Updating not performed to avoid duplication)."
    fi
else
    echo "Could not detect .bashrc or .zshrc. Add this manually:"
    echo "alias $ALIAS_NAME='$DOCKER_RUN_CMD'"
fi

echo "---"
echo "Setup Complete inside $REPO_ROOT"
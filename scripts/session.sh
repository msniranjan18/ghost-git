#!/bin/bash

# --- Robust Path Detection ---
# This works for both bash and zsh, and both sourcing and executing
if [ -n "$BASH_SOURCE" ]; then
    CURRENT_SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "$ZSH_VERSION" ]; then
    CURRENT_SCRIPT_PATH="${(%):-%N}"
else
    CURRENT_SCRIPT_PATH="$0"
fi

SCRIPT_DIR="$( cd "$( dirname "$CURRENT_SCRIPT_PATH" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
IDENTITY_DIR="$REPO_ROOT/.mygit-identity"

# --- Configuration ---
ALIAS_NAME="mygit-ssh"
KEY_PATH=$(find "$IDENTITY_DIR/.ssh" -type f \( -name "id_rsa" -o -name "id_ed25519" \) 2>/dev/null | head -n 1)

echo "Initializing GhostGit Session..."
echo "Identity Root: $IDENTITY_DIR"

# 1. Validation
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: No private key found in $IDENTITY_DIR/.ssh/"
    echo "Please ensure your key (id_rsa or id_ed25519) is in the folder."
    # Use return instead of exit so it doesn't close the user's terminal if sourced
    return 1 2>/dev/null || exit 1
fi

# 2. Secure Permissions
chmod 700 "$IDENTITY_DIR/.ssh"
chmod 600 "$KEY_PATH"

# 3. Start SSH Agent & Load Key
# We use eval to set the SSH_AUTH_SOCK and SSH_AGENT_PID in the current shell
eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"

# 4. The "Logout Guard" (Cleanup Logic)
# This kills the agent process as soon as the terminal session ends
trap "echo 'Killing GhostGit SSH Agent...'; ssh-agent -k" EXIT

# 5. Define Alias for this Session
# We use single quotes for the alias to ensure it handles arguments correctly
#alias mygit-ssh="docker run --rm -it --user 0:0 -v \"\$(pwd):/git\" -v \"$IDENTITY_DIR/.gitconfig:/root/.gitconfig:ro\" -v /run/host-services/ssh-auth.sock:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent -e GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' alpine/git"
# --- Detect the correct SSH Socket path ---
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use the Docker Desktop bridge
    AGENT_SOCK="/run/host-services/ssh-auth.sock"
else
    # Linux / WSL: Use the standard environment variable path
    AGENT_SOCK="$SSH_AUTH_SOCK"
fi

# --- Define the Cross-Platform Alias ---
alias mygit-ssh='docker run --rm -it --user 0:0 \
  -v "$(pwd):/git" \
  -v "'$IDENTITY_DIR'/.gitconfig:/root/.gitconfig:ro" \
  -v "'$AGENT_SOCK':/ssh-agent" \
  -e SSH_AUTH_SOCK=/ssh-agent \
  -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  alpine/git'

echo "--------------------------------------------------------"
echo "Identity Loaded: $(git config -f $IDENTITY_DIR/.gitconfig user.email)"
echo "Command Ready: $ALIAS_NAME <git command>"
echo "Note: This session and agent will auto-destruct on exit."
echo "type exit to close the session"
echo "--------------------------------------------------------"

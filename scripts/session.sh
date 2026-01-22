#!/bin/bash

# --- Configuration ---
IDENTITY_DIR="$HOME/.mygit-identity"
# Automatically detects the first key found in your identity folder
KEY_PATH=$(find "$IDENTITY_DIR/.ssh" -type f \( -name "id_rsa" -o -name "id_ed25519" \) | head -n 1)
ALIAS_NAME="mygit-ssh"

echo "🔑 Initializing GhostGit Session..."

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
# We use 'export' and 'alias' so the current terminal window is ready to go
export MYGIT_SSH_CMD="docker run --rm -it \
  -v \$(pwd):/git \
  -v $IDENTITY_DIR/.gitconfig:/root/.gitconfig:ro \
  -v \$SSH_AUTH_SOCK:/ssh-agent \
  -e SSH_AUTH_SOCK=/ssh-agent \
  alpine/git"

alias $ALIAS_NAME="$MYGIT_SSH_CMD"

echo "--------------------------------------------------------"
echo "Identity Loaded: $(git config -f $IDENTITY_DIR/.gitconfig user.email)"
echo "Command Ready: $ALIAS_NAME <git command>"
echo "Note: This session and agent will auto-destruct on exit."
echo "--------------------------------------------------------"

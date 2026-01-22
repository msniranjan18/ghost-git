#!/bin/bash

# --- Configuration ---
IDENTITY_DIR="$HOME/.mygit-identity"
ALIAS_NAME="mygit"
GIT_IMAGE="alpine/git"

echo "Starting mygit Docker setup..."

# 1. Create Identity Directory
if [ ! -d "$IDENTITY_DIR" ]; then
    mkdir -p "$IDENTITY_DIR/.ssh"
    echo "Created $IDENTITY_DIR"
else
    echo "Identity directory already exists."
fi

# 2. Check for .gitconfig
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
    echo "Action Required: Copy your private SSH keys (e.g., id_rsa) to $IDENTITY_DIR/.ssh/"
    echo "    Command: cp ~/.ssh/id_rsa $IDENTITY_DIR/.ssh/"
fi

# 4. Define the Alias Logic
DOCKER_RUN_CMD="docker run --rm -it \\
  -v \$(pwd):/git \\
  -v $IDENTITY_DIR/.gitconfig:/root/.gitconfig:ro \\
  -v $IDENTITY_DIR/.ssh:/root/.ssh:ro \\
  $GIT_IMAGE"

# 5. Detect Shell and Add Alias
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "alias $ALIAS_NAME=" "$SHELL_RC"; then
        echo "alias $ALIAS_NAME='$DOCKER_RUN_CMD'" >> "$SHELL_RC"
        echo "Added alias '$ALIAS_NAME' to $SHELL_RC"
        echo "Please run: source $SHELL_RC"
    else
        echo "Alias '$ALIAS_NAME' already exists in $SHELL_RC"
    fi
else
    echo "Could not detect .bashrc or .zshrc. Add this manually:"
    echo "alias $ALIAS_NAME='$DOCKER_RUN_CMD'"
fi

echo "---"
echo "Setup Complete!"
echo "Usage: $ALIAS_NAME clone <repo_url>"
echo "Usage: $ALIAS_NAME commit -m 'Message'"

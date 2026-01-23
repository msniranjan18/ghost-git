| Parameter                           | Technical Function |
|------------------------------------|--------------------|
| `--rm` Ephemeral Filesystem        | Automatically deletes the container instance the moment the Git command finishes. This ensures no logs, cached credentials, or temporary files persist on the system. |
| `-it` Interactive TTY              | Keeps stdin open and allocates a pseudo-TTY. This is required so that if Git/SSH asks for your key passphrase, you can see the prompt and type it. |
| `--user 0:0` UID/GID Mapping       | Forces the container to run as the root user. This is necessary because the `alpine/git` image defaults to a non-privileged user who would not have permission to read the SSH keys mounted into `/root/`. |
| `-v "$(pwd):/git"` Workspace Mount | Maps your current working directory to the `/git` folder inside the container. The `alpine/git` image runs Git commands from this directory by default. |
| `-v ".../.gitconfig:/root/.gitconfig:ro"` Identity Projection | Mounts your custom Git config file into the container. The `:ro` (read-only) flag ensures the container cannot modify your global Git configuration. |
| `-v ".../.ssh:/root/.ssh:ro"` Secret Mounting | Provides the container with access to your private SSH keys. By mounting to `/root/.ssh`, the SSH client inside the container can locate keys using its default path. |
| `-e GIT_SSH_COMMAND="..."` SSH Override | Sets an environment variable to control SSH behavior. For example, `StrictHostKeyChecking=no` prevents host verification prompts that can break automation. |
| `alpine/git` The Engine            | A minimal (~20 MB) Linux image that contains only Git and the SSH client, making it lightweight and secure for isolated Git operations. |

| Parameter	                      |      Technical Function|
-------------------------------------------------------------
| --rm	Ephemeral Filesystem: | Automatically deletes the container instance the moment the Git command finishes. This ensures no logs, cached credentials, or temporary files persist on the system. |  
| -it	Interactive TTY: | Keeps stdin open and allocates a pseudo-TTY. This is technically required so that if Git/SSH needs to ask for your Key Passphrase, you can actually see the prompt and type it in. |  
| --user 0:0	UID/GID Mapping: | Forces the container to run as the root user. This is necessary because the alpine/git image defaults to a non-privileged user who wouldn't have permission to read the sensitive SSH keys we mount into the /root/ directory. |  
| -v "$(pwd):/git"	Project Workspace Mounting: | Maps your current working directory on the Mac to the /git folder inside the Linux container. The alpine/git image is configured to automatically run Git commands inside /git. |  
| -v ".../.gitconfig:/root/.gitconfig:ro"	Identity Projection: | Mounts your custom Git config file. The :ro (Read-Only) flag is a security measure to ensure the container cannot modify your global identity settings. |  
| -v ".../.ssh:/root/.ssh:ro"	Secret Mounting: | Provides the container with access to your private SSH keys. By mounting it to /root/.ssh, the containerized SSH client looks there by default for authentication. |  
| -e GIT_SSH_COMMAND="..."	SSH Behavior Override: | Sets an environment variable that tells Git to use specific SSH flags. StrictHostKeyChecking=no prevents the "Do you trust this host?" prompt, which often breaks automated or containerized scripts. |  
| alpine/git	The Engine: | A tiny (approx. 20MB) Linux image containing only the Git binaries and SSH client. |  
	

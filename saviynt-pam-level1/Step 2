# Step 2: The Fragility of Manual JIT Scripting

Before turning to Saviynt, let's try to resolve this access crisis manually using standard Linux shell utilities to prove why homegrown scripts fail under pressure.

### 1. Execute a Manual JIT Access Command
Run this command to append a "temporary" public key string and schedule a background subshell to prune it exactly 30 seconds later:
```bash
echo "ssh-rsa AAAAB3Nza... temp_contractor_key" >> /home/deploy-admin/.ssh/authorized_keys && (sleep 30 && sed -i '/temp_contractor_key/d' /home/deploy-admin/.ssh/authorized_keys && echo "Key pruned successfully") &
```{{exec}}

### Shattering the Illusion of Manual Control:
* **The Persistence Risk:** While that key was active for 30 seconds, what stopped the contractor (or an attacker) from immediately executing `ssh-keygen` locally and adding a secondary, un-tracked backdoor key to the file?
* **The Reliability Risk:** If the Linux server crashes, reboots, or kills the background shell process during that 30-second window, the cleanup subshell dies—leaving the backdoor access authorized permanently.
* **The Audit Void:** Your internal compliance officer needs a structured log showing who approved this access, their active business justification, and proof of removal. A manual `sed` script provides none of this.

# Step 2: The Fragility of Manual JIT Scripting

Before turning to Saviynt, let's try to resolve this access crisis manually using standard Linux shell utilities to prove why homegrown security scripts fail under enterprise pressure.

### 1. Execute the Manual JIT Access Command
Click the command below to append a temporary public key string and schedule a background process to prune it exactly 30 seconds later:

```bash
echo "ssh-rsa AAAAB3Nza... temp_contractor_key" >> /home/deploy-admin/.ssh/authorized_keys && (sleep 30 && sed -i '/temp_contractor_key/d' /home/deploy-admin/.ssh/authorized_keys && echo "Key pruned successfully") &
```{{exec}}

---

### 2. Deconstructing the Bash Payload
Because you are a security engineer managing a live system, you must know exactly what each character of that command executed. Here is the operational breakdown:

* **`echo "..." >>`** 
  The `>>` operator *appends* data to the end of the `authorized_keys` file. If a single `>` was used by accident, it would overwrite and wipe out all existing keys, breaking current user access instantly.
* **`&&`**
  A logical AND. The second half of the command will *only* execute if the first step (the key append) succeeds without errors.
* **`(...) &`**
  The parenthesis group commands into a *subshell*, and the trailing `&` pushes that subshell into the background. This frees up your terminal line immediately rather than locking your screen for 30 seconds.
* **`sleep 30`**
  Forces the background process to wait exactly 30 seconds before advancing.
* **`sed -i '/.../d'`**
  Stream Editor (`sed`). The `-i` flag alters the file *inline* (directly modifying it). The `/temp_contractor_key/d` searches for that specific string label and *deletes* the entire line from the file.

---

### 3. Objection Handling Masterclass: Scripting vs. Saviynt Cloud PAM
In the real world, traditional Unix Admins will push back against buying a platform like Saviynt, arguing: *"I don't need expensive software; I can just write a cron job or a bash loop to expire keys for free."* 

As an Identity Security leader, you must dismantle that objection using the three operational realities discovered during this step:

| The Unix Admin Argument | The Enterprise Security Reality |
| :--- | :--- |
| **"My script clears the key automatically."** | **The Reliability Risk:** If the server crashes, reboots, or undergoes an automated scaling event during that 30-second window, the background subshell dies instantly. The cleanup phase is lost forever, turning your temporary key into a permanent backdoor. |
| **"The key is only active for a brief window."** | **The Persistence Risk:** While that key is active for 30 seconds, there is zero isolation. A malicious actor can log in instantly, generate a fresh `ssh-keygen` pair locally on the host, and drop a secondary, untracked backdoor key into the file. Your script deletes the first key, but the attacker retains permanent access. |
| **"My script logs the deletion to a local file."** | **The Audit Void (SOX/HIPAA):** Local text files lack integrity and can be altered by any user with `sudo` rights. Furthermore, a local script cannot answer: *Who requested this? Which manager approved it? What ServiceNow ticket justifies it?* |

---

### 4. Incident Report Update
Review your active Incident Report scratchpad. Add the following line to your documentation:

```text
Operational Mitigation Attempt: Manual Bash Scripting
 -> Result: Failed Enterprise Compliance Requirements
 -> Identified Vulnerabilities: Process fragility, lack of tamper-proof logging, vulnerability to lateral key persistence.

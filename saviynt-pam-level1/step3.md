# Step 3: Mitigation via Saviynt Cloud PAM Principles

Now, let's step out of the reactive firefighting mindset. In a real-world enterprise, **you would never install or register a security solution directly onto an active, compromised production server during a live breach.** Doing so violates change management and risks corrupting live transaction data.

Instead, this step demonstrates how Saviynt Cloud PAM is planned, architected, and deployed *upstream* during standard maintenance windows to ensure that static, permanent exposures like the GitHub leak can never happen in the first place.

---

### 1. Upstream Governance: Onboarding and Locking Down the Host
During a scheduled maintenance window, an organization registers its server infrastructure with Saviynt to eliminate "configuration drift" and local admin bypasses. 

Run the onboarding command to simulate this proactive baseline injection:
```bash
saviynt-cli onboard
```{{exec}}

**Test the Local Lockout:** Attempt to manually append a backdoor key to the file now:
```bash
echo "ssh-rsa AAAAB3_hacker_key" >> /home/deploy-admin/.ssh/authorized_keys
```{{exec}}

* **The Result:** The system rejects your command with a hard **bash: /home/deploy-admin/.ssh/authorized_keys: Operation not permitted** error. 
* **The Business Value:** Saviynt moves policy enforcement to the kernel level (`chattr +i`). By locking down the file structure, local administrative modifications are blocked. Even if a bad actor or rogue script gains root-level access later, they cannot drop a persistent backdoor key.
* **The Unix Admin Objection:** *"Locking local files breaks our automated configuration management tools (like Ansible or Chef) that need to push keys."*
* **The Counter-Argument:** Centralized infrastructure should not rely on static SSH keys distributed to local endpoints. Saviynt eliminates the need for configuration tools to manage keys locally by moving the gatekeeping upstream to an identity broker.

---

### 2. Eliminating Standing Privileges: Requesting 15-Second JIT Access
Instead of giving contractors a static private key file that can sit on their laptop for months (and eventually leak on GitHub), they are given **Zero Standing Privileges**. They must request an ephemeral window.

Execute a dynamic, short-lived Just-In-Time request:
```bash
saviynt-cli request-jit contractor.name@partner.com 15
```{{exec}}

* **The Business Value:** The attack surface is effectively zero. Because the key only exists on the system for 15 seconds, an attacker scanning the web for open port 22 connections has no permanent target to strike. 
* **The Developer Objection:** *"JIT requests create friction. If a system goes down at 3 AM, I don't want to wait 20 minutes for a manager to log in and approve my access."*
* **The Counter-Argument:** Saviynt handles this via **Automated Policy Integration**. If a critical incident ticket (e.g., a P1 ServiceNow ticket) matches the developer's request parameters, Saviynt instantly grants the JIT window without human delay, maintaining both speed and compliance.

---

### 3. Verification & The Frictionless Developer Experience
While the 15-second countdown is active, execute the provided SSH command to verify the agent successfully opened the access path:

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/jit_temp_key deploy-admin@localhost
```{{exec}}

* **The Experience:** Notice that you are now dropped directly into the `deploy-admin@linux-prod-db01` shell environment. Run a quick check command to see who you are:

```bash
whoami
```{{exec}}

* **The Clean Exit:** When you are done exploring the temporary environment, type **`exit`** and hit Enter to return safely to your `root` engineering terminal line:

```bash
exit
```{{exec}}

* **The Developer Objection:** *"Enterprise PAM tools force us to use clunky web portals, slow jump boxes, or proprietary connection managers. It breaks our native workflows and slows down incident response during 3 AM outages."*
* **The Business Value (Native UX):** Notice what *didn't* happen here. The contractor didn't have to log into a separate portal or learn a new tool. They used the exact same native Linux `ssh` command they always use. Saviynt handles the complex cryptography and authorization on the backend, preserving a **100% frictionless, native user experience** for the engineering teams. High security, zero operational drag.

### 4. Side-by-Side Log Analysis: Host vs. Identity View
Compare what the local operating system logged against what Saviynt captured.

**A. View the Local Host Log:**
```bash
tail -n 20 /var/log/auth.log | grep sshd
```{{exec}}

**B. View the Central Saviynt Audit Log:**
```bash
saviynt-cli audit-logs
```{{exec}}

* **The CISO Objection:** *"We already centralize all of our OS logs in a SIEM like Splunk. We don't need another logging tool."*
* **The Counter-Argument:** A SIEM can only correlate data that the host actually tracks. Look at `auth.log`—it only sees a shared account (`deploy-admin`) and a network address (`127.0.0.1`). If three different contractors use that account simultaneously, your SIEM cannot tell them apart. Saviynt binds the raw OS session directly to a verified corporate identity (`contractor.name@partner.com`) *at the moment of request*, translating technical telemetry into audit compliance.

---

### 5. Part 2: The Enriched Incident Report
Using the structured JSON payload from the Saviynt audit log, complete your compliance documentation:

```text
============================================================
INCIDENT REPORT - PART 2: SAVIYNT EIC STREAM INTEGRATION
============================================================
Target Hostname: linux-prod-db01
Proactive Security Posture: Onboarded & Managed Upstream

RESOLVED IDENTITY VARIABLES:
1. True Human Identity behind the session:  ________________
2. Upstream Governance User ID:            ________________
3. Approved Access Window Duration:        ____ Seconds
4. Mandatory Business Ticket Reference:    ________________
============================================================

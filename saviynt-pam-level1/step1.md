# Step 1: Analyze the Threat & Detect Active Sessions

### 0. Environmental Provisioning
Run this bootstrap command to deploy the Payment Gateway server, simulate the live incident, and inject background sessions:
```bash
curl -s [https://raw.githubusercontent.com/tommyro22/saviynt-active-labs/main/saviynt-pam-level1/setup.sh](https://raw.githubusercontent.com/tommyro22/saviynt-active-labs/main/saviynt-pam-level1/setup.sh) | tr -d '\r' | bash
```{{exec}}

---

### 1. Identify Your Environment Context
Before analyzing logs, you must understand exactly *who* and *where* you are within this Linux system. Run this command to discover your current identity and system access groups:
```bash
whoami && pwd && groups
```{{exec}}

* **The Reality Check:** You are currently logged in as the root user at the root directory. However, the compromise has occurred on a specific, non-root administrative account: `deploy-admin`.

---

### 2. The Core Mechanic: The SSH Cryptographic Handshake
Why is the `deploy-admin` account compromised just because a file was leaked on GitHub?
* **The Handshake:** SSH relies on public/private key pairs. The **public key** acts like a lock and lives on the server inside a specific user’s home directory (`~/.ssh/authorized_keys`). The **private key** acts like the physical key and is held by the remote user.
* **The Risk:** If an attacker acquires the private key (`payment-gateway-cluster.pem`), they bypass all password prompts and instantly inherit the exact permissions and privileges assigned to `deploy-admin` on this operating system.

---

### 3. Audit the Attacker's Blast Radius (Permissions)
Investigate exactly what capabilities an attacker inherits when they log in using that stolen key. Run this command to check the specific `sudo` (administrative) capabilities assigned to `deploy-admin`:
```bash
sudo -l -U deploy-admin
```{{exec}}

* **The Exposure:** Look at the output. `deploy-admin` has highly elevated or unrestricted access to run deployment tools and alter database states. The attacker does not need the root password; they already control the application.

---

### 4. Track Active Sessions (Who is on the box?)
An attacker using a key leaves a live footprint. Run this standard Linux utility to see every user session currently active on the system and where they connected from:
```bash
w
```{{exec}}

* **The Problem:** You see multiple active terminal sessions listed under the single `deploy-admin` account, originating from different remote IP addresses.

---

### 5. Part 1: The Blindspot Incident Report
Copy the layout below into a local text editor or scratchpad. Fill out the missing variables using the raw Linux data you discovered from `sudo -l` and `w`.

```text
============================================================
INCIDENT REPORT - PART 1: LOCAL HOST VISIBILITY
============================================================
Target Hostname?
Compromised OS Account?

OS Account Permissions (Blast Radius from sudo -l):
 -> 

Active Sessions Found (Output of 'w' command):
 -> Session 1 Account: deploy-admin | Source IP:
 -> Session 2 Account: deploy-admin | Source IP:

CRITICAL IDENTITY CHALLENGE:
1. Which session is the legitimate contractor?
2. Which session is the malicious threat actor?
3. Real Human Name behind Session 1:           
4. Real Human Name behind Session 2:          
============================================================

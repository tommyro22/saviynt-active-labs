# Step 3: Zero Trust via Identity Proxy

In the previous steps, we saw how relying on local host configurations (like static SSH keys) creates a massive security blind spot. Manual administration doesn't scale, and standing privileges inevitably lead to breached perimeters.

Instead of trying to manage local files better, **Saviynt EIC changes the architecture entirely.** Saviynt acts as a transparent **Secure Access Broker (Identity Proxy)**, abstracting access control away from the individual endpoint.

---

### 1. Requesting Ephemeral Access (Zero Standing Privileges)
Contractors and developers no longer hold static keys, nor do they need standing accounts on the servers. They simply request a dynamic, time-bound token from the Saviynt broker. 

Execute a 15-second Just-In-Time (JIT) request:

```bash
saviynt-cli request-jit contractor.name@partner.com 15
```{{exec}}

* **The Business Need:** Organizations need to eliminate the persistent attack surface of standing administrative accounts without spending six months deploying heavy software agents to every server in their fleet.
* **The Saviynt Value (Agentless Time-to-Value):** Notice that we didn't install a heavy Saviynt agent on this Linux box. Because Saviynt operates as an upstream Identity Proxy, you achieve **Zero Standing Privileges (ZSP)** instantly. The access token literally does not exist until the moment it is approved, drastically reducing deployment time and total cost of ownership.

---

### 2. Connect via the Secure Access Broker
While the 15-second countdown is active, connect to the server. Notice that you do not use a traditional `ssh` command or point to a local key file. The CLI routes you securely through the proxy:

```bash
saviynt-cli connect-session
```{{exec}}

* **The Experience:** You are instantly dropped into the target environment. Verify your access:

```bash
whoami
```{{exec}}

* **The Engineering Objection:** *"Security tools always slow us down. We hate logging into clunky web portals or jumping through extra hoops just to get a terminal session to fix a broken app."*
* **The Saviynt Value (Frictionless UX):** Saviynt delivers native protocol support. Engineers don't have to leave their command line or change their daily workflows. The Identity Proxy sits transparently in the middle, intercepting the request, validating the token, and spawning the session instantly. **High security, zero operational drag.**

When you are done validating your access, cleanly exit the proxy session:

```bash
exit
```{{exec}}

---

### 3. The Automated Lifecycle (Wait and Re-Test)
Wait a few seconds for the JIT timer to hit zero. The background engine will automatically revoke the token. Attempt to connect again:

```bash
saviynt-cli connect-session
```{{exec}}

* **The Result:** The broker rejects the connection with an `Access Denied` error. The cutoff is absolute and immune to local OS manipulation.

---

### 4. The Auditor's View (Provable Compliance)
When a breach happens—or when SOX/PCI auditors arrive—raw operating system logs are useless. A standard Linux `auth.log` only shows that the generic `deploy-admin` account logged in from an IP address. It tells you nothing about the human being behind the keyboard.

Pull the structured audit ledger from the Saviynt control plane:

```bash
saviynt-cli audit-logs
```{{exec}}

* **The Saviynt Value (Identity-Enriched Telemetry):** Look at the JSON output. Saviynt translates raw machine data into a human narrative. It maps the exact human identity (`contractor.name@partner.com`), the governance policy invoked (`Zero-Trust-Proxy`), and the exact status of the elevated access. 
* **The Business Outcome:** What used to take security teams hours of manual correlation between IT service tickets, HR data, and raw server logs is now available instantly. This makes passing audits frictionless and drastically accelerates incident response.

You have successfully secured the environment and proven compliance. Click **Next** to complete the workshop.

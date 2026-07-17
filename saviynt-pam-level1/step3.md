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

* **The Result:** The broker rejects the connection with an `Access Denied` error. 
* **The Saviynt Value (Provable Compliance):** The lifecycle is fully automated. There is no human error, no forgot-to-delete-the-key, and no lingering access. When an auditor asks for proof that contractor access was revoked, the proxy provides absolute, cryptographic certainty that the session was terminated exactly when the approved window expired.

Click **Next** to generate the final enriched incident report and prove compliance.

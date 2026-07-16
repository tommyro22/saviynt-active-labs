# Step 1: Analyze the Threat & Detect Active Sessions

Let's locate the leaked credential on the host and identify running connections.

### 1. View the Exposed Key
Verify that the leaked private key exists on your local system:
`cat /home/deploy-admin/leaked_key.pem`{{exec}}

### 2. Verify the Active Session
Check the local system's active background processes. You will notice that an active administrative process is currently running under the shared `deploy-admin` account (representing the external contractor's session):
`ps aux | grep deploy-admin`{{exec}}

### 3. Analyze Authentication Logs
Read the authorization log to see where active connections originated:
`cat /var/log/auth.log | grep sshd`{{exec}}

### The Identity Friction
As a Security Engineer, you can see a session is active, but **who** actually logged in? Because they are using a shared static SSH key, you have **zero traceability** connecting the UNIX account to a real human identity. 

If a malicious actor uses this exact same leaked key from a rogue IP while the contractor is working, your logs will look identical.

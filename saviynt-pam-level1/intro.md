# Scenario: Static Key Exposure and the PAM Dilemma

Welcome to the hot seat.

### The Persona & Context
You are the **Lead Identity Security Engineer** on duty during a high-traffic release weekend for your company’s core **Payment Gateway**. The Unix Systems Administration team is completely off-line, and you are the sole line of defense.

### The Threat Discovery
At 02:14 AM, an external Threat Intelligence monitoring tool flagged a public GitHub repository leak. A file named `leaked_key.pem` was committed. Its cryptographic MD5 hash matches the active, administrative private key used to access your production Payment Gateway server. 

### The Blast Radius (Why We Can't Just Pull the Plug)
* **High Financial Stakes:** This server processes £50,000 in transactions per minute. 
* **Zero Downtime Window:** You cannot run `sudo reboot`, change firewalls, or pull the network plug. Doing so triggers a massive site-reliability incident, costing millions in revenue and violating strict SLA mandates.
* **The Active Risk:** Contractors are actively scheduled to use this administrative account (`deploy-admin`) to monitor the release tonight. You cannot simply delete the key and lock them out without breaking the deployment.

### Your Mission
You must investigate the active environment, attempt a manual stop-gap fix using standard Linux commands (to understand why traditional administrative methods fail), and then implement **Saviynt Cloud PAM Just-In-Time (JIT) workflow principles** to secure the server without disrupting business operations.
### The Deliverable 
You will maintain a two-part Incident Report to document your findings, first using raw Linux logs, then upgrading it with Saviynt’s identity telemetry to expose critical security blindspots.

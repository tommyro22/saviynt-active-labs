#!/bin/bash
clear
echo -e "\e[33m[*] Initializing Vulnerable Linux Target... Please wait.\e[0m"

# 1. Start SSH daemon, enforce pubkey auth, and restore clean slate
mkdir -p /run/sshd
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
service ssh restart > /dev/null 2>&1

W_PATH=$(which w 2>/dev/null || echo "/usr/bin/w")
if [ -f "${W_PATH}.bak" ]; then
    mv "${W_PATH}.bak" "$W_PATH"
fi
chattr -i /home/deploy-admin/.ssh/authorized_keys 2>/dev/null
userdel -r deploy-admin 2>/dev/null
rm -f /usr/local/bin/w

# 2. Create target deploy-admin user and assign dangerous privileges
useradd -m -s /bin/bash deploy-admin
mkdir -p /home/deploy-admin/.ssh
chmod 700 /home/deploy-admin/.ssh

# INJECT THE BLAST RADIUS: Grant passwordless sudo for critical payment gateway commands
echo "deploy-admin ALL=(root) NOPASSWD: /usr/bin/systemctl restart payment-gateway, /usr/bin/psql" > /etc/sudoers.d/deploy-admin
chmod 440 /etc/sudoers.d/deploy-admin

# 3. Generate a mock "leaked" static key pair matching the incident scope
ssh-keygen -t ed25519 -f /tmp/leaked_id_rsa -N "" -q
cat /tmp/leaked_id_rsa.pub > /home/deploy-admin/.ssh/authorized_keys
mv /tmp/leaked_id_rsa /home/deploy-admin/leaked_key.pem
chmod 600 /home/deploy-admin/.ssh/authorized_keys
chown -R deploy-admin:deploy-admin /home/deploy-admin/

# 4. Simulate active, un-audited background contractor/attacker connections in auth.log
echo "Jul 17 02:15:12 linux-prod-db01 sshd[4321]: Accepted publickey for deploy-admin from 198.51.100.42 port 49152 ssh2: RSA SHA256:leakedfingerprint..." >> /var/log/auth.log
echo "Jul 17 02:18:44 linux-prod-db01 sshd[4325]: Accepted publickey for deploy-admin from 203.0.113.88 port 51002 ssh2: RSA SHA256:leakedfingerprint..." >> /var/log/auth.log
nohup sudo -u deploy-admin sleep 3600 > /dev/null 2>&1 &

# 5. Weaponize the Mock: Back up the real binary and overwrite it at its source location
cp "$W_PATH" "${W_PATH}.bak"
cat << 'EOF' > "$W_PATH"
#!/bin/bash
TIMESTAMP=$(date +%H:%M:%S)
UPTIME=$(uptime -p 2>/dev/null || echo "up 1 hour")
echo " ${TIMESTAMP} ${UPTIME},  3 users,  load average: 0.02, 0.04, 0.00"
printf "%-10s %-7s %-16s %-6s %-6s %-6s %-6s %s\n" "USER" "TTY" "FROM" "LOGIN@" "IDLE" "JCPU" "PCPU" "WHAT"
printf "%-10s %-7s %-16s %-6s %-6s %-6s %-6s %s\n" "root" "pts/0" "10.0.2.2" "02:10" "0.00s" "0.04s" "0.00s" "w"
printf "%-10s %-7s %-16s %-6s %-6s %-6s %-6s %s\n" "deploy-admin" "pts/1" "198.51.100.42" "02:15" "3:14"  "0.02s" "0.01s" "-bash"
printf "%-10s %-7s %-16s %-6s %-6s %-6s %-6s %s\n" "deploy-admin" "pts/2" "203.0.113.88"  "02:18" "1:02"  "0.01s" "0.01s" "-bash"
EOF
chmod +x "$W_PATH"

# 6. Write the simulated Saviynt CLI tool with explicit policy locks and rich JSON telemetry
cat << 'EOF' > /usr/local/bin/saviynt-cli
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

function show_banner {
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "${CYAN}   SAVIYNT ENTERPRISE IDENTITY CLOUD (EIC) PAM ENGINE   ${NC}"
    echo -e "${CYAN}            - COMPLIANCE & JIT SIMULATOR -             ${NC}"
    echo -e "${CYAN}=======================================================${NC}"
}

if [ "$1" == "onboard" ]; then
    show_banner
    echo -e "${YELLOW}[*] Registering host 'linux-prod-db01' with Saviynt IGA Control Plane...${NC}"
    sleep 1.5
    
    # REMEDIATION: Wipe the compromised static keys file entirely
    chattr -i /home/deploy-admin/.ssh/authorized_keys 2>/dev/null
    > /home/deploy-admin/.ssh/authorized_keys
    
    # FIX: Correct ownership alignment for OpenSSH StrictModes validation
    chown deploy-admin:deploy-admin /home/deploy-admin/.ssh/authorized_keys
    chmod 600 /home/deploy-admin/.ssh/authorized_keys
    
    # RESTORATION: Automatically restore the genuine 'w' binary to clear fake sessions
    W_PATH=$(which w 2>/dev/null || echo "/usr/bin/w")
    if [ -f "${W_PATH}.bak" ]; then
        mv "${W_PATH}.bak" "$W_PATH"
    fi
    
    # THE STEEL CAGE: Make the file completely immutable at the kernel layer
    chattr +i /home/deploy-admin/.ssh/authorized_keys
    
    echo -e "${GREEN}[+] Host successfully onboarded to Saviynt EIC!${NC}"
    echo -e "${RED}[!] CRITICAL: Local authentication architecture is now LOCKED.${NC}"
    echo -e "${RED}[!] Direct manual key injection will now fail with OS-level errors.${NC}"
    exit 0
fi

if [ "$1" == "request-jit" ]; then
    show_banner
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}[!] Error: Missing operational parameters.${NC}"
        echo -e "Usage: saviynt-cli request-jit <contractor_email> <duration_sec>"
        exit 1
    fi
    CONTRACTOR="$2"
    DURATION="$3"
    
    echo -e "${YELLOW}[*] Interrogating Saviynt upstream Policy Engine...${NC}"
    sleep 1
    echo -e "${GREEN}[+] Dynamic JIT request approved for Identity: $CONTRACTOR${NC}"
    echo -e "${YELLOW}[*] Temporarily cycling system immutable bits for safe injection...${NC}"
    
   # CLEAN SWEEP: Erase any historical keys to prevent overwrite prompt loops
    rm -f /tmp/jit_temp_key /tmp/jit_temp_key.pub
    
    chattr -i /home/deploy-admin/.ssh/authorized_keys 2>/dev/null
    
    # UPGRADE: Use ed25519 to bypass modern OpenSSH RSA restrictions
    ssh-keygen -t ed25519 -f /tmp/jit_temp_key -N "" -q
    cat /tmp/jit_temp_key.pub >> /home/deploy-admin/.ssh/authorized_keys
    
    # FIX: Maintain StrictModes validation capability for the incoming loopback connection
    chown deploy-admin:deploy-admin /home/deploy-admin/.ssh/authorized_keys
    chmod 600 /home/deploy-admin/.ssh/authorized_keys
    
    chattr +i /home/deploy-admin/.ssh/authorized_keys
    
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    RAND_ID=$((10000 + RANDOM % 90000))
    USER_ID=$((1000 + RANDOM % 9000))
    
    cat << JSON >> /var/log/saviynt_pam.log
{
  "eventId": "PAM-JIT-${RAND_ID}",
  "timestamp": "${TIMESTAMP}",
  "action": "ElevatedAccessGranted",
  "status": "SUCCESS",
  "resource": {
    "endpoint": "linux-prod-db01",
    "accountName": "deploy-admin",
    "type": "Production Server"
  },
  "identity": {
    "requestor": "${CONTRACTOR}",
    "saviyntUserId": "USR-${USER_ID}"
  },
  "policy": {
    "name": "Zero-Trust-Ephemeral-SSH",
    "durationSeconds": ${DURATION},
    "approvalReason": "Emergency Payment Gateway Release Modification",
    "ticketReference": "SNOW-99281"
  },
  "audit": {
    "sessionRecordingEnabled": true,
    "keystrokeLogging": "Active",
    "mappedFromIp": "198.51.100.42"
  }
}
JSON
    
    echo -e "${GREEN}[+] Ephemeral token injected. Temporary operational access active.${NC}"
    echo -e "Temporary Private Key Location: /tmp/jit_temp_key"
    echo -e "Execute verification test: ${YELLOW}ssh -o StrictHostKeyChecking=no -i /tmp/jit_temp_key deploy-admin@localhost${NC}"
    
    (
        sleep $DURATION
        TEMP_KEY_CONTENT=$(cat /tmp/jit_temp_key.pub 2>/dev/null)
        if [ ! -z "$TEMP_KEY_CONTENT" ]; then
            chattr -i /home/deploy-admin/.ssh/authorized_keys 2>/dev/null
            grep -v "$TEMP_KEY_CONTENT" /home/deploy-admin/.ssh/authorized_keys > /tmp/temp_auth
            cat /tmp/temp_auth > /home/deploy-admin/.ssh/authorized_keys
            rm -f /tmp/temp_auth /tmp/jit_temp_key /tmp/jit_temp_key.pub
            chown deploy-admin:deploy-admin /home/deploy-admin/.ssh/authorized_keys
            chmod 600 /home/deploy-admin/.ssh/authorized_keys
            chattr +i /home/deploy-admin/.ssh/authorized_keys
            
            TIMESTAMP_PRUNE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            cat << JSON >> /var/log/saviynt_pam.log
{
  "eventId": "PAM-JIT-CLEANUP-${RAND_ID}",
  "timestamp": "${TIMESTAMP_PRUNE}",
  "action": "ElevatedAccessRevoked",
  "status": "SUCCESS",
  "resource": {
    "endpoint": "linux-prod-db01",
    "accountName": "deploy-admin"
  },
  "identity": {
    "requestor": "${CONTRACTOR}"
  },
  "policy": {
    "status": "ExpiredAndPrunedAutomatic"
  }
}
JSON
        fi
    ) &
    exit 0
fi

if [ "$1" == "audit-logs" ]; then
    show_banner
    echo -e "${CYAN}[*] Streaming structured audit ledger from Saviynt control line:${NC}"
    if [ -f /var/log/saviynt_pam.log ]; then
        cat /var/log/saviynt_pam.log
    else
        echo "[-] Zero captured identity governance metrics found."
    fi
    exit 0
fi

show_banner
echo "Available Commands:"
echo "  saviynt-cli onboard                      Remediate breach, lock host files down via kernel attributes"
echo "  saviynt-cli request-jit <email> <sec>    Authorize short-lived human-to-account dynamic SSH linkage"
echo "  saviynt-cli audit-logs                   View identity-enriched compliance JSON stream"
EOF

chmod +x /usr/local/bin/saviynt-cli
echo -e "\e[32m[+] Payment Gateway Target Environment Initialized Successfully.\e[0m"
sleep 1.5
clear

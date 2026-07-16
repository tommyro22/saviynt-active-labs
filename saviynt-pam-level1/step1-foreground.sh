#!/bin/bash
exec > /var/log/killercoda-bootstrap.log 2>&1

# 1. Create target deploy-admin user
useradd -m -s /bin/bash deploy-admin
mkdir -p /home/deploy-admin/.ssh
chmod 700 /home/deploy-admin/.ssh

# Generate a mock "leaked" static key pair
ssh-keygen -t rsa -b 2048 -f /tmp/leaked_id_rsa -N "" -q
cat /tmp/leaked_id_rsa.pub > /home/deploy-admin/.ssh/authorized_keys
mv /tmp/leaked_id_rsa /home/deploy-admin/leaked_key.pem
chmod 600 /home/deploy-admin/.ssh/authorized_keys
chown -R deploy-admin:deploy-admin /home/deploy-admin/

# 2. Simulate active, un-audited background contractor activity
echo "Jul 16 14:22:15 target-server sshd[1234]: Accepted publickey for deploy-admin from 198.51.100.42 port 49152 ssh2: RSA SHA256:leakedfingerprint..." >> /var/log/auth.log
sudo -u deploy-admin sleep 3600 &

# 3. Write the simulated Saviynt CLI tool
cat << 'EOF' > /usr/local/bin/saviynt-cli
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

function show_banner {
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "${CYAN}   SAVIYNT ENTERPRISE IDENTITY CLOUD (EIC) AGENT       ${NC}"
    echo -e "${CYAN}               - PAM SIMULATOR MVP -                   ${NC}"
    echo -e "${CYAN}=======================================================${NC}"
}

if [ "$1" == "onboard" ]; then
    show_banner
    echo -e "${YELLOW}[*] Onboarding server to Saviynt EIC Platform...${NC}"
    sleep 2
    # Simulate a Zero Trust Lockdown of local SSH authorization
    chown root:root /home/deploy-admin/.ssh/authorized_keys
    chmod 600 /home/deploy-admin/.ssh/authorized_keys
    echo -e "${GREEN}[+] Server 'linux-prod-target' successfully registered!${NC}"
    echo -e "${GREEN}[+] Local authentication files locked. Drift monitoring enabled.${NC}"
    exit 0
fi

if [ "$1" == "request-jit" ]; then
    show_banner
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}[!] Error: Missing arguments.${NC}"
        echo -e "Usage: saviynt-cli request-jit <approver_email> <duration_sec>"
        exit 1
    fi
    APPROVER="$2"
    DURATION="$3"
    
    echo -e "${YELLOW}[*] Contacting Saviynt EIC Controller...${NC}"
    sleep 1
    echo -e "${GREEN}[+] JIT access approved by: $APPROVER${NC}"
    echo -e "${YELLOW}[*] Injecting ephemeral public key for $DURATION seconds...${NC}"
    
    ssh-keygen -t rsa -b 2048 -f /tmp/jit_temp_key -N "" -q
    chown root:root /home/deploy-admin/.ssh/authorized_keys
    cat /tmp/jit_temp_key.pub >> /home/deploy-admin/.ssh/authorized_keys
    
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"timestamp\": \"$TIMESTAMP\", \"event\": \"JIT_KEY_INJECTED\", \"requester\": \"partner-operator\", \"approver\": \"$APPROVER\", \"target\": \"deploy-admin\", \"ttl_seconds\": $DURATION}" >> /var/log/saviynt_pam.log
    
    echo -e "${GREEN}[+] Key dynamically active. Test connection now.${NC}"
    echo -e "Temporary private key: /tmp/jit_temp_key"
    echo -e "Command to test: ${YELLOW}ssh -o StrictHostKeyChecking=no -i /tmp/jit_temp_key deploy-admin@localhost${NC}"
    
    # Pruning Daemon Simulation
    (
        sleep $DURATION
        TEMP_KEY_CONTENT=$(cat /tmp/jit_temp_key.pub 2>/dev/null)
        if [ ! -z "$TEMP_KEY_CONTENT" ]; then
            grep -v "$TEMP_KEY_CONTENT" /home/deploy-admin/.ssh/authorized_keys > /tmp/temp_auth
            cat /tmp/temp_auth > /home/deploy-admin/.ssh/authorized_keys
            rm -f /tmp/temp_auth /tmp/jit_temp_key /tmp/jit_temp_key.pub
            TIMESTAMP_PRUNE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            echo "{\"timestamp\": \"$TIMESTAMP_PRUNE\", \"event\": \"JIT_KEY_PRUNED\", \"target\": \"deploy-admin\", \"status\": \"Success\"}" >> /var/log/saviynt_pam.log
        fi
    ) &
    exit 0
fi

if [ "$1" == "audit-logs" ]; then
    show_banner
    echo -e "${CYAN}[*] Fetching central audit stream from EIC console:${NC}"
    if [ -f /var/log/saviynt_pam.log ]; then
        cat /var/log/saviynt_pam.log
    else
        echo "No audit events captured yet."
    fi
    exit 0
fi

show_banner
echo "Available commands:"
echo "  saviynt-cli onboard                      Lock host down and register with controller"
echo "  saviynt-cli request-jit <email> <sec>    Request short-lived dynamic SSH access"
echo "  saviynt-cli audit-logs                   View immutable IGA audit events"
EOF

chmod +x /usr/local/bin/saviynt-cli
touch /var/log/killercoda-setup-done

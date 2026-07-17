#!/bin/bash
clear
echo -e "\e[33m[*] Initializing Vulnerable Linux Target... Please wait.\e[0m"

# 1. Clean slate
W_PATH=$(which w 2>/dev/null || echo "/usr/bin/w")
if [ -f "${W_PATH}.bak" ]; then
    mv "${W_PATH}.bak" "$W_PATH"
fi
userdel -r deploy-admin 2>/dev/null
rm -f /usr/local/bin/w /tmp/jit_token

# 2. Create target deploy-admin user and assign dangerous privileges
useradd -m -s /bin/bash deploy-admin
mkdir -p /home/deploy-admin/.ssh

# INJECT THE BLAST RADIUS: Grant passwordless sudo for critical payment gateway commands
echo "deploy-admin ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl restart payment-gateway, /usr/bin/psql" >> /etc/sudoers

# 3. Create the "Leaked Key" narrative (Simulating the vulnerability)
echo "ssh-rsa AAAAB3_leaked_hacker_key..." > /home/deploy-admin/.ssh/authorized_keys
chown -R deploy-admin:deploy-admin /home/deploy-admin

# 4. Simulate active hacker connections in auth.log
echo "Jul 17 02:15:12 linux-prod-db01 sshd[4321]: Accepted publickey for deploy-admin from 198.51.100.42" >> /var/log/auth.log
echo "Jul 17 02:18:44 linux-prod-db01 sshd[4325]: Accepted publickey for deploy-admin from 203.0.113.88" >> /var/log/auth.log

# 5. Weaponize the Mock 'w' command
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

# 6. Write the simulated Saviynt CLI tool (Identity Proxy Edition)
cat << 'EOF' > /usr/local/bin/saviynt-cli
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

function show_banner {
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "${CYAN}   SAVIYNT SECURE ACCESS (IDENTITY PROXY) SIMULATOR    ${NC}"
    echo -e "${CYAN}=======================================================${NC}"
}

if [ "$1" == "onboard" ]; then
    show_banner
    echo -e "${YELLOW}[*] Routing host 'linux-prod-db01' behind Saviynt Identity Proxy...${NC}"
    sleep 1
    
    # Remediation: Nuke the file and lock it down forever
    chattr -i /home/deploy-admin/.ssh/authorized_keys 2>/dev/null
    > /home/deploy-admin/.ssh/authorized_keys
    chattr +i /home/deploy-admin/.ssh/authorized_keys
    
    # Restore 'w' binary to clear hacker sessions
    W_PATH=$(which w 2>/dev/null || echo "/usr/bin/w")
    if [ -f "${W_PATH}.bak" ]; then
        mv "${W_PATH}.bak" "$W_PATH"
    fi
    
    echo -e "${GREEN}[+] Host successfully onboarded! Native SSH bypass is now blocked.${NC}"
    exit 0
fi

if [ "$1" == "request-jit" ]; then
    show_banner
    CONTRACTOR="$2"
    DURATION="$3"
    
    echo -e "${YELLOW}[*] Validating Identity Risk via Saviynt EIC...${NC}"
    sleep 1
    echo -e "${GREEN}[+] JIT request approved for: $CONTRACTOR${NC}"
    
    # Create the secure time-bound token
    echo "ACTIVE" > /tmp/jit_token
    
    # Background expiration daemon
    (
        sleep $DURATION
        rm -f /tmp/jit_token
        echo -e "\n${RED}[!] JIT Window Expired. Access token revoked by Saviynt Engine.${NC}" > /dev/tty
    ) &
    
    echo -e "${GREEN}[+] Broker session primed. Access window: ${DURATION} seconds.${NC}"
    echo -e "Execute verification test: ${YELLOW}saviynt-cli connect-session${NC}"
    exit 0
fi

if [ "$1" == "connect-session" ]; then
    if [ -f /tmp/jit_token ]; then
        echo -e "${GREEN}[+] Vault Token Validated. Brokering secure session to deploy-admin...${NC}"
        # Spawn the subshell, simulating the proxy hand-off
        sudo -u deploy-admin bash -c "PS1='deploy-admin@linux-prod-db01 (Saviynt Brokered)$ ' bash --noprofile --norc"
    else
        echo -e "${RED}[!] Access Denied: No active JIT window found, or session has expired.${NC}"
    fi
    exit 0
fi

if [ "$1" == "audit-logs" ]; then
    show_banner
    echo -e "${CYAN}[*] Streaming structured audit ledger:${NC}"
    echo '{ "eventId": "PAM-JIT-9921", "action": "ElevatedAccessGranted", "status": "SUCCESS", "identity": "contractor@partner.com", "policy": "Zero-Trust-Proxy" }' | jq . 2>/dev/null || echo -e "{\n  \"eventId\": \"PAM-JIT-9921\",\n  \"action\": \"ElevatedAccessGranted\",\n  \"identity\": \"contractor.name@partner.com\",\n  \"policy\": \"Zero-Trust-Proxy\"\n}"
    exit 0
fi

show_banner
echo "Commands:"
echo "  saviynt-cli onboard                      Lock down local host, route via Identity Proxy"
echo "  saviynt-cli request-jit <email> <sec>    Authorize short-lived access token"
echo "  saviynt-cli connect-session              Connect via Saviynt Secure Access"
echo "  saviynt-cli audit-logs                   View identity-enriched compliance logs"
EOF

chmod +x /usr/local/bin/saviynt-cli
echo -e "\e[32m[+] Target Environment Initialized Successfully.\e[0m"
sleep 1
clear

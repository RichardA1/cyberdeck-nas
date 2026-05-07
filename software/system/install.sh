#!/bin/bash

################################################################################
# Cyberdeck NAS - Automated Installation Script
# Phase 1: Core Setup
#
# This script automates the initial setup of a Raspberry Pi 4 for Cyberdeck NAS
# It handles:
#   - System updates and hardening
#   - User account creation and configuration
#   - WiFi and network setup (templates)
#   - Service directories and permissions
#   - Initial security configuration
#
# Usage: sudo ./install.sh
# Requires: Ubuntu 22.04 LTS ARM64 or Raspberry Pi OS Lite 64-bit
#
# Author: Richard A. (Cyberdeck Team)
# License: GNU GPLv3
# Date: May 2026
################################################################################

set -euo pipefail

# Color output for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
CYBERDECK_USER="cyberdeck"
CYBERDECK_HOME="/home/$CYBERDECK_USER"
CYBERDECK_OPT="/opt/cyberdeck"
CYBERDECK_LOG="/var/log/cyberdeck"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use: sudo ./install.sh)"
        exit 1
    fi
}

check_os() {
    if ! grep -qi "ubuntu\|raspberry" /etc/os-release; then
        log_error "This script requires Ubuntu or Raspberry Pi OS"
        exit 1
    fi
    log_success "OS check passed"
}

check_internet() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warn "No internet connection detected. Some features may not work."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "Internet connection OK"
    fi
}

check_disk_space() {
    local available=$(df /opt 2>/dev/null | awk 'NR==2 {print $4}')
    if [ "$available" -lt 1048576 ]; then  # 1GB
        log_error "Insufficient disk space (need 1GB+, have $(($available/1024))MB)"
        exit 1
    fi
    log_success "Disk space check passed"
}

################################################################################
# Phase 1: System Updates & Base Installation
################################################################################

install_base_system() {
    log_info "=== Phase 1: Base System Installation ==="
    
    log_info "Updating package lists..."
    apt-get update
    
    log_info "Upgrading system packages..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    
    log_info "Installing core dependencies..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        python3-dev python3-pip python3-venv \
        git curl wget ca-certificates \
        libffi-dev libssl-dev \
        systemd-timesyncd \
        wpasupplicant \
        dnsmasq isc-dhcp-server \
        hostapd \
        mosquitto mosquitto-clients \
        fail2ban ufw \
        htop iotop ncdu \
        rsync logrotate \
        nano vim \
        jq bc \
        wiringpi pigpio \
        i2c-tools \
        ntp ntpstat
    
    log_success "Base system installation complete"
}

################################################################################
# Phase 2: User Account Setup
################################################################################

setup_user() {
    log_info "=== Phase 2: User Account Setup ==="
    
    if id "$CYBERDECK_USER" &>/dev/null; then
        log_warn "User $CYBERDECK_USER already exists, skipping creation"
    else
        log_info "Creating $CYBERDECK_USER account..."
        useradd -m -s /bin/bash -G sudo,gpio,i2c,spi "$CYBERDECK_USER"
        log_success "User $CYBERDECK_USER created"
    fi
    
    log_info "Setting up sudo without password for service commands..."
    cat >> /etc/sudoers.d/cyberdeck <<EOF
# Cyberdeck service commands
$CYBERDECK_USER ALL=(ALL) NOPASSWD: /bin/systemctl start cyberdeck*
$CYBERDECK_USER ALL=(ALL) NOPASSWD: /bin/systemctl stop cyberdeck*
$CYBERDECK_USER ALL=(ALL) NOPASSWD: /bin/systemctl restart cyberdeck*
$CYBERDECK_USER ALL=(ALL) NOPASSWD: /bin/systemctl status cyberdeck*
$CYBERDECK_USER ALL=(ALL) NOPASSWD: /usr/local/bin/wireless_setup.sh
$CYBERDECK_USER ALL=(ALL) NOPASSWD: /usr/sbin/hostapd_cli
EOF
    chmod 440 /etc/sudoers.d/cyberdeck
    log_success "Sudo configuration complete"
}

################################################################################
# Phase 3: Directory Structure & Permissions
################################################################################

setup_directories() {
    log_info "=== Phase 3: Directory Structure Setup ==="
    
    # Create main directories
    mkdir -p "$CYBERDECK_OPT"/{api,services,config,scripts}
    mkdir -p "$CYBERDECK_LOG"
    mkdir -p "$CYBERDECK_HOME"/.ssh
    mkdir -p "$CYBERDECK_HOME"/.config/cyberdeck
    
    # Create data directories
    mkdir -p /var/lib/cyberdeck/{db,media,wiki,backups}
    
    # Set permissions
    chown -R "$CYBERDECK_USER:$CYBERDECK_USER" "$CYBERDECK_OPT"
    chown -R "$CYBERDECK_USER:$CYBERDECK_USER" "$CYBERDECK_HOME"
    chown -R "$CYBERDECK_USER:$CYBERDECK_USER" /var/lib/cyberdeck
    chmod 755 "$CYBERDECK_OPT"
    chmod 750 "$CYBERDECK_HOME"/.ssh
    chmod 700 "$CYBERDECK_HOME"/.config
    
    # Create systemd drop-in directories
    mkdir -p /etc/systemd/system/cyberdeck-*.service.d
    
    log_success "Directory structure created"
}

################################################################################
# Phase 4: Networking & Hostname Setup
################################################################################

setup_networking() {
    log_info "=== Phase 4: Networking Configuration ==="
    
    # Set hostname
    log_info "Setting hostname to 'cyberdeck'..."
    hostnamectl set-hostname cyberdeck
    sed -i 's/127.0.1.1.*/127.0.1.1 cyberdeck/' /etc/hosts
    
    # Disable WiFi power saving (for stability)
    log_info "Disabling WiFi power management..."
    cat > /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf <<EOF
[connection]
wifi.powersave = 2
EOF
    
    # Configure systemd-resolved for local DNS
    log_info "Configuring DNS resolution..."
    cat >> /etc/systemd/resolved.conf <<EOF

# Cyberdeck DNS configuration
FallbackDNS=8.8.8.8 8.8.4.4 1.1.1.1
DNSSEC=no
EOF
    
    systemctl restart systemd-resolved
    log_success "Networking configuration complete"
}

################################################################################
# Phase 5: System Security Hardening (Basic)
################################################################################

harden_security() {
    log_info "=== Phase 5: Basic Security Hardening ==="
    
    # SSH configuration
    log_info "Hardening SSH configuration..."
    cat >> /etc/ssh/sshd_config.d/cyberdeck.conf <<EOF
# Cyberdeck SSH Hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
    
    # Test SSH config
    if ! sshd -t; then
        log_error "SSH configuration test failed"
        exit 1
    fi
    systemctl restart ssh
    
    # UFW firewall setup
    log_info "Configuring firewall (UFW)..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (custom port will be configured later)
    ufw allow 22/tcp
    
    # Allow common services
    ufw allow 80/tcp   # HTTP (API)
    ufw allow 443/tcp  # HTTPS (API)
    ufw allow 3000/tcp # Web Dashboard
    ufw allow 8000/tcp # FastAPI
    
    # Allow mDNS
    ufw allow 5353/udp
    
    log_success "Firewall enabled with basic rules"
    
    # fail2ban for brute force protection
    log_info "Configuring fail2ban..."
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = root@localhost
sendername = Cyberdeck

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log

[recidive]
enabled = true
action = iptables-multiport[name=recidive, port="http,https,ssh", protocol=tcp]
filter = recidive
logpath = /var/log/fail2ban.log
bantime = 604800
findtime = 86400
maxretry = 5
EOF
    
    systemctl restart fail2ban
    log_success "fail2ban configured"
    
    # Disable unnecessary services
    log_info "Disabling unnecessary services..."
    for service in avahi-daemon bluetooth cups; do
        if systemctl is-enabled "$service" &>/dev/null; then
            systemctl disable "$service"
            systemctl stop "$service" || true
        fi
    done
    
    log_success "Security hardening complete"
}

################################################################################
# Phase 6: Python Environment Setup
################################################################################

setup_python() {
    log_info "=== Phase 6: Python Environment Setup ==="
    
    log_info "Creating Python virtual environment..."
    python3 -m venv "$CYBERDECK_OPT/venv"
    
    log_info "Upgrading pip, setuptools, wheel..."
    "$CYBERDECK_OPT/venv/bin/pip" install --upgrade pip setuptools wheel
    
    log_info "Installing core Python dependencies..."
    "$CYBERDECK_OPT/venv/bin/pip" install \
        fastapi \
        uvicorn \
        sqlalchemy \
        pydantic \
        pydantic-settings \
        python-jose[cryptography] \
        passlib[bcrypt] \
        python-multipart \
        requests \
        paho-mqtt \
        bleak \
        Adafruit-PureIO \
        RPi.GPIO
    
    # Create activation script wrapper
    cat > "$CYBERDECK_OPT/activate.sh" <<'EOF'
#!/bin/bash
source /opt/cyberdeck/venv/bin/activate
export PYTHONPATH="/opt/cyberdeck:$PYTHONPATH"
EOF
    chmod +x "$CYBERDECK_OPT/activate.sh"
    
    chown -R "$CYBERDECK_USER:$CYBERDECK_USER" "$CYBERDECK_OPT/venv"
    log_success "Python environment ready"
}

################################################################################
# Phase 7: Service Template Files
################################################################################

setup_service_templates() {
    log_info "=== Phase 7: Systemd Service Templates ==="
    
    # API Service template
    cat > /etc/systemd/system/cyberdeck-api.service.template <<'EOF'
[Unit]
Description=Cyberdeck NAS API Server
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=cyberdeck
Group=cyberdeck
WorkingDirectory=/opt/cyberdeck
ExecStart=/opt/cyberdeck/venv/bin/uvicorn api.main:app --host 0.0.0.0 --port 8000 --log-level info
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cyberdeck-api
Environment="PYTHONUNBUFFERED=1"
Environment="PATH=/opt/cyberdeck/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF
    
    # MQTT Broker service template
    cat > /etc/systemd/system/cyberdeck-mqtt.service.template <<'EOF'
[Unit]
Description=Cyberdeck MQTT Broker (Mosquitto)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=mosquitto
Group=mosquitto
ExecStart=/usr/sbin/mosquitto -c /etc/mosquitto/conf.d/cyberdeck.conf
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cyberdeck-mqtt

[Install]
WantedBy=multi-user.target
EOF
    
    # Health check service template
    cat > /etc/systemd/system/cyberdeck-health.service.template <<'EOF'
[Unit]
Description=Cyberdeck System Health Monitor
After=network-online.target

[Service]
Type=simple
User=cyberdeck
Group=cyberdeck
ExecStart=/opt/cyberdeck/scripts/health_check.sh
Restart=on-failure
RestartSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Timer for regular health checks
    cat > /etc/systemd/system/cyberdeck-health.timer <<'EOF'
[Unit]
Description=Cyberdeck Health Check Timer

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    log_success "Service templates created"
}

################################################################################
# Phase 8: Logging & Rotation
################################################################################

setup_logging() {
    log_info "=== Phase 8: Logging Configuration ==="
    
    # Create logrotate config
    cat > /etc/logrotate.d/cyberdeck <<'EOF'
/var/log/cyberdeck/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 cyberdeck cyberdeck
    sharedscripts
    postrotate
        systemctl reload cyberdeck-api > /dev/null 2>&1 || true
    endscript
}
EOF
    
    # Create systemd journal config
    mkdir -p /etc/systemd/journald.conf.d
    cat > /etc/systemd/journald.conf.d/cyberdeck.conf <<'EOF'
[Journal]
MaxRetentionSec=4week
SystemMaxUse=1G
RuntimeMaxUse=100M
EOF
    
    systemctl restart systemd-journald
    log_success "Logging configuration complete"
}

################################################################################
# Phase 9: Final Configuration & Information
################################################################################

create_info_script() {
    log_info "=== Phase 9: Creating Info & Reference Scripts ==="
    
    # Create system info script
    cat > "$CYBERDECK_OPT/scripts/system_info.sh" <<'EOF'
#!/bin/bash
echo "=== Cyberdeck System Information ==="
echo "Hostname: $(hostname)"
echo "IP Addresses:"
hostname -I
echo ""
echo "CPU Info:"
grep -m 1 -oP 'ARMv\K[0-9]+' /proc/cpuinfo || echo "ARM CPU"
lscpu | grep -E "CPU|MHz|cache"
echo ""
echo "Memory:"
free -h
echo ""
echo "Disk Usage:"
df -h /
echo ""
echo "Service Status:"
systemctl status cyberdeck-* --no-pager 2>/dev/null || echo "Services not yet installed"
echo ""
echo "Network:"
ip link show | grep -E "^[0-9]|state UP"
echo ""
echo "Temperature:"
vcgencmd measure_temp 2>/dev/null || echo "Temperature monitoring not available"
EOF
    chmod +x "$CYBERDECK_OPT/scripts/system_info.sh"
    
    # Create next-steps guide
    cat > "$CYBERDECK_OPT/NEXT_STEPS.txt" <<'EOF'
=== Cyberdeck NAS - Phase 1 Installation Complete ===

Next steps to finalize your Cyberdeck NAS setup:

1. SSH KEY SETUP (Recommended)
   Generate SSH keys on your computer:
   $ ssh-keygen -t ed25519 -C "cyberdeck@$(hostname -f)"
   
   Copy public key to Cyberdeck:
   $ ssh-copy-id -i ~/.ssh/id_ed25519.pub cyberdeck@cyberdeck.local
   
   Verify key-based login:
   $ ssh -i ~/.ssh/id_ed25519 cyberdeck@cyberdeck.local

2. NETWORK CONFIGURATION
   Configure WiFi AP and Client mode:
   $ sudo /opt/cyberdeck/wireless_setup.sh
   
   This will guide you through:
   - Setting WiFi SSID and passphrase
   - Configuring WiFi client for backhaul
   - Testing connectivity

3. VERIFY INSTALLATION
   Check system information and status:
   $ /opt/cyberdeck/scripts/system_info.sh
   
   View system logs:
   $ journalctl -u cyberdeck-* -f

4. NEXT PHASE (Phase 2: Wireless Integration)
   When ready to proceed, you'll install:
   - MQTT broker
   - LoRa module GPIO configuration
   - BLE services
   - Initial API framework

For detailed documentation, see:
- Technical Spec: /opt/cyberdeck/docs/TECHNICAL_SPEC.md
- Security Guide: /opt/cyberdeck/docs/SECURITY_HARDENING.md
- Troubleshooting: /opt/cyberdeck/docs/TROUBLESHOOTING.md

=== System Ready for Phase 2 ===
EOF
    
    log_success "Info scripts created"
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       Cyberdeck NAS - Automated Installation Script           ║"
    echo "║                     Phase 1: Core Setup                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Starting installation ($(date '+%Y-%m-%d %H:%M:%S'))"
    
    check_root
    check_os
    check_internet
    check_disk_space
    
    install_base_system
    setup_user
    setup_directories
    setup_networking
    harden_security
    setup_python
    setup_service_templates
    setup_logging
    create_info_script
    
    # Final message
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          ✓ Phase 1 Installation Complete!                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Installation finished at $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    log_info "Important next steps:"
    echo "  1. Configure wireless: sudo /opt/cyberdeck/wireless_setup.sh"
    echo "  2. Setup SSH keys for key-based authentication"
    echo "  3. View system info: /opt/cyberdeck/scripts/system_info.sh"
    echo ""
    log_info "For detailed instructions, see /opt/cyberdeck/NEXT_STEPS.txt"
    echo ""
    log_warn "System will now reboot to apply security changes"
    echo ""
    read -p "Press Enter to reboot, or Ctrl+C to abort: " -r
    
    reboot
}

# Run main function
main "$@"

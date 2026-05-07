#!/bin/bash

################################################################################
# Cyberdeck NAS - Wireless Configuration Script
# 
# Interactive script to configure:
#   - WiFi Access Point (AP) mode
#   - WiFi Client mode (for backhaul/internet)
#   - Dual-mode WiFi (AP on 2.4GHz, Client on 5GHz, or vice versa)
#
# Usage: sudo /opt/cyberdeck/wireless_setup.sh
# Requires: hostapd, dnsmasq, wpa_supplicant
#
# License: GNU GPLv3
################################################################################

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration files
HOSTAPD_CONF="/etc/hostapd/cyberdeck.conf"
DNSMASQ_CONF="/etc/dnsmasq.d/cyberdeck.conf"
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant-client.conf"
NETPLAN_DIR="/etc/netplan"

################################################################################
# Helper Functions
################################################################################

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

get_wifi_interface() {
    # Find WiFi interface (usually wlan0)
    local iface=$(iw dev 2>/dev/null | grep "Interface" | head -1 | awk '{print $2}')
    if [ -z "$iface" ]; then
        iface="wlan0"
    fi
    echo "$iface"
}

validate_passphrase() {
    local pass="$1"
    if [ ${#pass} -lt 8 ] || [ ${#pass} -gt 63 ]; then
        log_error "Passphrase must be 8-63 characters"
        return 1
    fi
    return 0
}

validate_ssid() {
    local ssid="$1"
    if [ ${#ssid} -lt 1 ] || [ ${#ssid} -gt 32 ]; then
        log_error "SSID must be 1-32 characters"
        return 1
    fi
    return 0
}

################################################################################
# Access Point Configuration
################################################################################

configure_ap_mode() {
    log_info "=== WiFi Access Point Configuration ==="
    echo ""
    
    # Get WiFi interface
    WIFI_IFACE=$(get_wifi_interface)
    log_info "Using WiFi interface: $WIFI_IFACE"
    
    # Get SSID
    local ssid=""
    while true; do
        read -p "Enter WiFi SSID (network name) [cyberdeck]: " ssid
        ssid="${ssid:-cyberdeck}"
        if validate_ssid "$ssid"; then
            break
        fi
    done
    
    # Get Passphrase
    local pass=""
    while true; do
        read -sp "Enter WiFi passphrase (8-63 chars): " pass
        echo
        if validate_passphrase "$pass"; then
            read -sp "Confirm passphrase: " pass_confirm
            echo
            if [ "$pass" = "$pass_confirm" ]; then
                break
            else
                log_warn "Passphrases don't match, try again"
            fi
        fi
    done
    
    # Get WiFi channel
    read -p "Enter WiFi channel (1-13, default 6): " channel
    channel="${channel:-6}"
    
    # Get IP subnet
    read -p "Enter AP IP address (default 192.168.4.1): " ap_ip
    ap_ip="${ap_ip:-192.168.4.1}"
    
    # Generate hostapd config
    log_info "Generating hostapd configuration..."
    cat > "$HOSTAPD_CONF" <<EOF
# Cyberdeck WiFi Access Point Configuration
interface=$WIFI_IFACE
driver=nl80211
ssid=$ssid
hw_mode=g
channel=$channel
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=$pass
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey_period=86400
ap_isolate=1
beacon_int=100
dtim_period=2
EOF
    
    log_success "hostapd config created at $HOSTAPD_CONF"
    
    # Generate dnsmasq config
    log_info "Generating dnsmasq configuration..."
    cat > "$DNSMASQ_CONF" <<EOF
# Cyberdeck DHCP/DNS Configuration for AP mode
interface=$WIFI_IFACE
dhcp-range=192.168.4.50,192.168.4.150,12h
dhcp-option=option:router,192.168.4.1
dhcp-option=option:dns-server,192.168.4.1
domain-needed
bogus-priv
server=/cyberdeck.local/192.168.4.1
local=/cyberdeck.local/
address=/cyberdeck.local/192.168.4.1
listen-address=192.168.4.1
bind-dynamic
EOF
    
    log_success "dnsmasq config created at $DNSMASQ_CONF"
    
    # Configure network interface
    log_info "Configuring network interface $WIFI_IFACE..."
    cat > "$NETPLAN_DIR/99-cyberdeck-ap.yaml" <<EOF
network:
  version: 2
  wifis:
    $WIFI_IFACE:
      dhcp4: false
      addresses:
        - $ap_ip/24
      nameservers:
        addresses: [192.168.4.1, 8.8.8.8]
      access-points:
        "$ssid": {}
EOF
    
    # Create systemd service override for hostapd
    mkdir -p "/etc/systemd/system/hostapd.service.d"
    cat > "/etc/systemd/system/hostapd.service.d/cyberdeck.conf" <<'EOF'
[Unit]
After=networking.service
Wants=networking.service

[Service]
ExecStart=
ExecStart=/usr/sbin/hostapd -B /etc/hostapd/cyberdeck.conf
Restart=on-failure
RestartSec=5
Type=forking
EOF
    
    log_success "Network interface configured"
    
    # Enable and start services
    log_info "Enabling services..."
    systemctl daemon-reload
    systemctl enable hostapd dnsmasq
    
    log_info "Starting services..."
    systemctl restart networking || true
    systemctl restart hostapd || true
    systemctl restart dnsmasq || true
    
    echo ""
    log_success "Access Point Configuration Complete!"
    echo ""
    echo "AP Details:"
    echo "  SSID: $ssid"
    echo "  IP Address: $ap_ip"
    echo "  Channel: $channel"
    echo "  Security: WPA2-PSK"
    echo ""
    log_info "Device will be accessible at http://$ap_ip:8000 (API)"
    echo ""
}

################################################################################
# WiFi Client Configuration
################################################################################

configure_client_mode() {
    log_info "=== WiFi Client Configuration (for Backhaul) ==="
    echo ""
    
    WIFI_IFACE=$(get_wifi_interface)
    log_info "Using WiFi interface: $WIFI_IFACE"
    
    # Scan for networks
    log_info "Scanning for available WiFi networks..."
    iwlist $WIFI_IFACE scan 2>/dev/null | grep -E "SSID|Signal" || log_warn "Could not scan networks"
    echo ""
    
    # Get SSID
    read -p "Enter SSID to connect to: " client_ssid
    [ -z "$client_ssid" ] && { log_error "SSID cannot be empty"; return 1; }
    
    # Get Passphrase
    read -sp "Enter WiFi passphrase: " client_pass
    echo
    
    # Select security type
    echo ""
    echo "Select security type:"
    echo "  1) WPA2-PSK"
    echo "  2) WPA3-SAE"
    echo "  3) Open (no password)"
    read -p "Choice (1-3, default 1): " sec_choice
    sec_choice="${sec_choice:-1}"
    
    # Generate WPA Supplicant config
    log_info "Generating wpa_supplicant configuration..."
    
    cat > "$WPA_CONF" <<EOF
# Cyberdeck WiFi Client Configuration
country=US
ctrl_interface=/run/wpa_supplicant
update_config=1

network={
    ssid="$client_ssid"
EOF
    
    case $sec_choice in
        1)
            cat >> "$WPA_CONF" <<'EOF'
    psk_passphrase="$client_pass"
    key_mgmt=WPA-PSK
    proto=WPA2
EOF
            ;;
        2)
            cat >> "$WPA_CONF" <<'EOF'
    passphrase="$client_pass"
    key_mgmt=SAE
    proto=WPA3
EOF
            ;;
        3)
            cat >> "$WPA_CONF" <<'EOF'
    key_mgmt=NONE
EOF
            ;;
    esac
    
    cat >> "$WPA_CONF" <<'EOF'
}
EOF
    
    chmod 600 "$WPA_CONF"
    log_success "WPA Supplicant config created"
    
    # Enable DHCPv4
    log_info "Configuring DHCP for client mode..."
    cat > "$NETPLAN_DIR/99-cyberdeck-client.yaml" <<EOF
network:
  version: 2
  wifis:
    $WIFI_IFACE:
      dhcp4: true
      optional: true
      access-points:
        "$client_ssid":
          password: "$client_pass"
EOF
    
    # Enable wpa_supplicant
    systemctl daemon-reload
    systemctl enable wpa_supplicant@$WIFI_IFACE || true
    
    log_info "Restarting networking..."
    systemctl restart networking || true
    
    # Wait for connection
    log_info "Waiting for connection (up to 30 seconds)..."
    for i in {1..30}; do
        if iwconfig $WIFI_IFACE 2>/dev/null | grep -q "ESSID:\"$client_ssid\""; then
            log_success "Connected to $client_ssid"
            break
        fi
        sleep 1
    done
    
    echo ""
}

################################################################################
# Dual Mode Configuration
################################################################################

configure_dual_mode() {
    log_info "=== Dual-Mode WiFi Configuration ==="
    echo ""
    log_warn "Dual-mode WiFi requires special hardware support (some RPi4 models)"
    echo ""
    
    read -p "Continue with dual-mode setup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    log_error "Dual-mode setup is not yet fully implemented"
    log_info "For now, configure AP and Client separately with different interfaces"
}

################################################################################
# Testing & Validation
################################################################################

test_connectivity() {
    log_info "=== Testing Connectivity ==="
    echo ""
    
    WIFI_IFACE=$(get_wifi_interface)
    
    log_info "WiFi interface status:"
    iwconfig $WIFI_IFACE
    
    echo ""
    log_info "Network interfaces:"
    ip link show
    
    echo ""
    log_info "IP addresses:"
    ip addr show $WIFI_IFACE
    
    echo ""
    log_info "Testing internet connectivity..."
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "Internet access available"
    else
        log_warn "Internet not accessible (may be normal for AP-only mode)"
    fi
    
    echo ""
    log_info "Testing DNS resolution..."
    if nslookup google.com &>/dev/null; then
        log_success "DNS resolution working"
    else
        log_warn "DNS resolution not working"
    fi
}

################################################################################
# Main Menu
################################################################################

show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      Cyberdeck NAS - Wireless Configuration Tool          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Select configuration mode:"
    echo ""
    echo "  1) Configure WiFi Access Point (AP)"
    echo "  2) Configure WiFi Client (for backhaul/internet)"
    echo "  3) Configure Dual-Mode (AP + Client)"
    echo "  4) Test Current Connectivity"
    echo "  5) View Current Configuration"
    echo "  6) Reset to Defaults"
    echo "  7) Exit"
    echo ""
}

view_config() {
    log_info "=== Current Wireless Configuration ==="
    echo ""
    
    if [ -f "$HOSTAPD_CONF" ]; then
        echo "hostapd config:"
        grep -E "^ssid|^channel|^interface" "$HOSTAPD_CONF" || echo "  Not configured"
    else
        echo "hostapd: Not configured"
    fi
    
    echo ""
    
    if [ -f "$DNSMASQ_CONF" ]; then
        echo "dnsmasq config:"
        grep -E "interface|dhcp-range" "$DNSMASQ_CONF" || echo "  Not configured"
    else
        echo "dnsmasq: Not configured"
    fi
    
    echo ""
    
    if [ -f "$WPA_CONF" ]; then
        echo "WiFi Client: Configured"
    else
        echo "WiFi Client: Not configured"
    fi
    
    echo ""
}

reset_config() {
    log_warn "This will reset all wireless configuration!"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Stopping services..."
        systemctl stop hostapd dnsmasq wpa_supplicant@* 2>/dev/null || true
        systemctl disable hostapd dnsmasq wpa_supplicant@* 2>/dev/null || true
        
        log_info "Removing configurations..."
        rm -f "$HOSTAPD_CONF" "$DNSMASQ_CONF" "$WPA_CONF"
        rm -f "$NETPLAN_DIR"/99-cyberdeck-*.yaml
        
        log_success "Configuration reset to defaults"
    fi
}

################################################################################
# Main Loop
################################################################################

main() {
    check_root
    
    while true; do
        show_menu
        read -p "Enter choice (1-7): " choice
        
        case $choice in
            1) configure_ap_mode ;;
            2) configure_client_mode ;;
            3) configure_dual_mode ;;
            4) test_connectivity ;;
            5) view_config ;;
            6) reset_config ;;
            7) log_success "Exiting"; exit 0 ;;
            *) log_error "Invalid choice" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"

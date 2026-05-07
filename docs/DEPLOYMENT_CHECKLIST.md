# Phase 1: Core Setup - Deployment Checklist

**Phase 1 Objective:** Establish a functional Raspberry Pi 4 NAS with hardened security, networking foundations, and system health monitoring.

**Timeline:** Week 1-2 of project  
**Status:** Ready for deployment  
**Last Updated:** May 2026

---

## Pre-Deployment Hardware Verification

### Physical Assembly
- [ ] Raspberry Pi 4B unboxed and inspected (no visible damage)
- [ ] Heatsinks applied to CPU and RAM (optional, but recommended)
- [ ] SD card inserted properly
- [ ] USB SSD connected via USB-C hub
- [ ] Power bank charged and tested
- [ ] All connections verified (no loose cables)
- [ ] Enclosure prepared with mounting points

### Component Testing (Before First Boot)
- [ ] Pi boots without power bank (SD card + USB power)
- [ ] SSD recognized by BIOS
- [ ] LED indicators respond normally (green/red activity)
- [ ] USB hub recognized (if applicable)

---

## Installation & Setup

### Phase 1a: OS Installation (30 minutes)

**Preparation:**
- [ ] Download Ubuntu Server 22.04 LTS ARM64 ISO
  ```bash
  # From https://ubuntu.com/download/raspberry-pi
  # or Raspberry Pi OS Lite 64-bit from https://www.raspberrypi.org/downloads/
  ```
- [ ] Download and install Raspberry Pi Imager (or Balena Etcher)
- [ ] Have USB card reader available
- [ ] Computer with internet connection for downloading

**Installation:**
- [ ] Flash OS to SD card (minimum 32GB recommended)
  ```bash
  # Using Raspberry Pi Imager
  1. Insert SD card into card reader
  2. Launch Raspberry Pi Imager
  3. Choose Ubuntu 22.04 LTS ARM64 for Pi 4
  4. Select SD card as destination
  5. Write image (10-15 minutes)
  ```
- [ ] Eject SD card safely
- [ ] Insert SD card into Raspberry Pi
- [ ] Connect power bank via USB-C
- [ ] Wait for first boot (2-3 minutes)
- [ ] Verify power LED is solid green (running)

### Phase 1b: Initial Network Access (20 minutes)

**Find Pi on Network:**
```bash
# On your computer, find the Pi's IP
# Option 1: Check router's DHCP client list
# Option 2: Use ARP scan
arp-scan --localnet | grep -i raspberry

# Option 3: Try mDNS
ping -c 1 ubuntu.local  # or pi.local for Raspberry Pi OS
```

- [ ] IP address identified
- [ ] SSH access confirmed
  ```bash
  ssh ubuntu@<ip-address>
  # Default password: ubuntu (change immediately)
  ```
- [ ] Change default password
  ```bash
  passwd
  # Enter new strong password (20+ chars recommended)
  ```

### Phase 1c: Automated Installation (45 minutes)

**Download Installation Script:**
```bash
# On the Pi
wget https://raw.githubusercontent.com/RichardA1/cyberdeck-nas/main/software/system/install.sh
chmod +x install.sh
```

- [ ] Script downloaded successfully
- [ ] Verify script integrity (check line count, look for obvious errors)
- [ ] Run installation
  ```bash
  sudo ./install.sh
  # This will take 30-45 minutes depending on download speed
  ```
- [ ] Monitor installation for errors
  - [ ] Base system packages installed
  - [ ] Cyberdeck user created
  - [ ] Directories structured
  - [ ] Networking configured
  - [ ] Security hardening applied
  - [ ] Python environment setup
  - [ ] Systemd services configured
  - [ ] Logging configured

- [ ] **System reboots automatically when complete**
- [ ] Wait 2-3 minutes for reboot
- [ ] Pi is back online (ping test)

### Phase 1d: Post-Installation Configuration (30 minutes)

**SSH Key Setup (Secure Alternative to Passwords):**

On your computer:
```bash
# Generate new SSH key for Cyberdeck
ssh-keygen -t ed25519 -C "cyberdeck@$(hostname -f)" -f ~/.ssh/id_cyberdeck

# Copy public key to Cyberdeck
ssh-copy-id -i ~/.ssh/id_cyberdeck.pub cyberdeck@<ip-address>

# Test key-based login (should not prompt for password)
ssh -i ~/.ssh/id_cyberdeck cyberdeck@<ip-address>
```

- [ ] SSH key generated on local machine
- [ ] Public key copied to Cyberdeck
- [ ] Key-based login verified (no password prompt)
- [ ] Password login tested (should fail if key works)

**Wireless Configuration:**

On the Pi:
```bash
sudo /opt/cyberdeck/wireless_setup.sh
```

- [ ] Script launched successfully
- [ ] Menu displayed correctly
- [ ] Selected Option 1: Configure WiFi Access Point
  - [ ] Set SSID (e.g., "cyberdeck")
  - [ ] Set secure passphrase (20+ chars, no dictionary words)
  - [ ] Selected channel (6 is default, good for 2.4GHz)
  - [ ] hostapd config created
  - [ ] dnsmasq config created
  - [ ] Services started

- [ ] Verify WiFi AP is broadcasting
  - [ ] From another device, scan WiFi networks
  - [ ] "cyberdeck" SSID visible
  - [ ] Can connect with correct passphrase
  - [ ] Test connectivity: `ping cyberdeck.local`

---

## Functional Testing

### System Health Checks

**Run System Info Script:**
```bash
/opt/cyberdeck/scripts/system_info.sh
```

- [ ] Hostname shows "cyberdeck"
- [ ] CPU info displays correctly
- [ ] Memory shows available RAM (should be 7.5GB+ of 8GB)
- [ ] Disk shows 100%+ GB available on /
- [ ] Temperature displayed (if available)
- [ ] Network interfaces list wlan0 and eth0

**Check Services:**
```bash
systemctl status cyberdeck-* --no-pager
```

- [ ] Examine all cyberdeck service templates
- [ ] Note any failures (normal if services not yet deployed)

### Network Tests

**From WiFi AP connected device:**
```bash
# Test connectivity
ping cyberdeck.local
ping 192.168.4.1  # AP IP address

# Test web API (will fail - Phase 2)
curl http://cyberdeck.local:8000/api/v1/status
# Expected: Connection refused (API not deployed yet)
```

- [ ] mDNS resolution working (cyberdeck.local resolves)
- [ ] Ping successful from AP clients
- [ ] Multiple devices can connect to AP simultaneously (test with 3+ devices)
- [ ] DHCP working (clients get IPs 192.168.4.50+)

**Optional: Client Mode Test**
```bash
# If you have a WiFi network to connect to
sudo /opt/cyberdeck/wireless_setup.sh
# Select Option 2: Configure WiFi Client
# Enter your SSID and passphrase
```

- [ ] Pi connects to external WiFi successfully
- [ ] Can ping external network
- [ ] Can access internet (test with `ping 8.8.8.8`)

### Security Verification

**SSH Hardening Check:**
```bash
# Try to SSH with password (should fail)
ssh ubuntu@<ip>
# Expected: Permission denied (pubkey,password).

# SSH with key (should work)
ssh -i ~/.ssh/id_cyberdeck cyberdeck@<ip>
```

- [ ] Password authentication blocked
- [ ] Key authentication working
- [ ] Custom SSH port configured (check in /etc/ssh/sshd_config.d/cyberdeck.conf)

**Firewall Check:**
```bash
sudo ufw status
```

- [ ] UFW enabled
- [ ] Rules show expected ports (22, 80, 443, 8000, 3000, 5353)
- [ ] Incoming connections dropped by default

**fail2ban Check:**
```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

- [ ] fail2ban running
- [ ] sshd filter enabled
- [ ] Monitoring SSH logs

### Disk & Storage Tests

**SSD Recognition:**
```bash
lsblk -S
sudo fdisk -l
```

- [ ] External SSD visible (likely /dev/sda)
- [ ] Correct size shown (1TB = ~931GB)
- [ ] If first boot, partition and format
  ```bash
  sudo mkfs.ext4 /dev/sda1
  sudo mkdir -p /mnt/ssd
  sudo mount /dev/sda1 /mnt/ssd
  ```

- [ ] [ ] SSD mounted at /mnt/ssd
- [ ] [ ] Can write test file
  ```bash
  echo "test" | sudo tee /mnt/ssd/test.txt
  cat /mnt/ssd/test.txt
  ```

- [ ] [ ] Add to /etc/fstab for permanent mounting
  ```bash
  sudo bash -c 'echo "/dev/sda1 /mnt/ssd ext4 defaults,nofail 0 2" >> /etc/fstab'
  ```

### Performance Benchmarks

**CPU Performance:**
```bash
sysbench cpu --cpu-max-prime=20000 run
```

- [ ] Baseline recorded (for comparison in future phases)
- [ ] No thermal throttling noticed (temp < 70°C)

**Disk I/O:**
```bash
sudo fio --name=test --ioengine=sync --rw=rw --bs=4k --numjobs=1 --size=100M --runtime=60
```

- [ ] Read speed > 200 MB/s (SSD expected)
- [ ] Write speed > 150 MB/s

**Memory:**
```bash
memtester 1G 1
```

- [ ] Memory test passes (no errors)

---

## Power Testing (Optional but Recommended)

**Equipment Needed:**
- USB power meter (Charger Doctor, Keweisi, or similar)
- USB-C meter (some power banks have built-in, or USB-C inline meter)

**Test Procedures:**

**Idle Mode (Headless):**
```bash
# SSH in and let system idle
# No WiFi AP, minimal services
```

- [ ] Measure current draw: ____ mA (target: 200-250mA)
- [ ] Calculate power: ____ mW (target: 1-1.3W @ 5V)
- [ ] Record in `/opt/cyberdeck/POWER_LOG.txt`

**WiFi AP Active:**
```bash
# Enable WiFi AP, don't connect clients
# Leave running for 5 minutes
```

- [ ] Measure current draw: ____ mA (target: 800-1000mA)
- [ ] Calculate power: ____ mW (target: 4-5W @ 5V)

**WiFi AP + Clients Connected:**
```bash
# Connect 5+ devices to WiFi AP
# Generate traffic (ping, file transfers)
```

- [ ] Measure current draw: ____ mA (target: 1200-1500mA)
- [ ] Calculate power: ____ mW (target: 6-7.5W @ 5V)

**Results:**
- [ ] Average power consumption within expectations
- [ ] No excessive spikes
- [ ] Temperature stable (< 70°C under load)

---

## Documentation & Handover

### Generate System Report

```bash
# Create system snapshot
/opt/cyberdeck/scripts/system_info.sh > ~/cyberdeck_report_$(date +%Y%m%d).txt

# Copy to secure location
scp -i ~/.ssh/id_cyberdeck cyberdeck@<ip>:~/cyberdeck_report_*.txt ./
```

- [ ] System report generated
- [ ] Report saved to local machine
- [ ] Key configuration documented

### Backup Initial State

```bash
# Create disk image for rollback
sudo dd if=/dev/sda of=cyberdeck_phase1_image.img bs=4M status=progress

# Compress for storage
gzip cyberdeck_phase1_image.img
```

- [ ] SD card image created (optional)
- [ ] Full SSD image created (may take 30+ minutes)
- [ ] Image stored on external drive

### Create Runbook

Document your specific setup:
- [ ] WiFi AP SSID and passphrase stored securely
- [ ] IP addresses documented
- [ ] SSH key locations documented
- [ ] Power management notes
- [ ] Customizations made
- [ ] Known issues documented

---

## Common Issues & Troubleshooting

### Issue: Pi doesn't boot
**Solutions:**
- [ ] Check SD card is fully inserted
- [ ] Try different USB power source
- [ ] Inspect for physical damage
- [ ] Re-flash SD card with Ubuntu image

### Issue: Can't connect to WiFi
**Solutions:**
- [ ] Run `sudo /opt/cyberdeck/wireless_setup.sh` again
- [ ] Check hostapd status: `sudo systemctl status hostapd`
- [ ] View logs: `sudo journalctl -u hostapd -n 20`
- [ ] Ensure channel isn't crowded (use `iwlist wlan0 scan`)

### Issue: SSH connection refused
**Solutions:**
- [ ] Verify IP address is correct
- [ ] Check SSH key permissions: `chmod 600 ~/.ssh/id_cyberdeck`
- [ ] Verify SSH service running: `systemctl status ssh`
- [ ] Check firewall rules: `sudo ufw status`

### Issue: SSD not detected
**Solutions:**
- [ ] Verify USB connection
- [ ] Try different USB port
- [ ] Check dmesg for errors: `sudo dmesg | tail -20`
- [ ] Try `sudo lsblk -S` to list storage devices
- [ ] Check if needs partitioning

### Issue: High power consumption (> 2W idle)
**Solutions:**
- [ ] Disable unnecessary services
- [ ] Reduce WiFi transmit power (advanced, Phase 2)
- [ ] Check for runaway processes: `top -b -n 1`
- [ ] Verify CPU frequency scaling: `watch -n 1 vcgencmd measure_clock arm`

---

## Phase 1 Sign-Off

### Deployment Status

- [ ] Hardware assembled and tested
- [ ] OS installed and booted
- [ ] Cyberdeck user account created
- [ ] WiFi AP configured and operational
- [ ] SSH key-based authentication working
- [ ] Firewall and fail2ban active
- [ ] System health monitoring functional
- [ ] Power consumption baseline established
- [ ] All services templates in place
- [ ] Documentation complete

### Proceed to Phase 2?

Once all checkboxes above are completed:

```bash
# Commit to GitHub
cd cyberdeck-nas
git add -A
git commit -m "Phase 1: Core setup complete

- Ubuntu 22.04 LTS installed and hardened
- WiFi AP/Client mode templates configured
- Security hardening (SSH, firewall, fail2ban) implemented
- Python 3.10+ environment with virtual venv
- Systemd service templates for API, MQTT, health monitoring
- Power baseline established: 1.2W idle, 4.5W with WiFi AP
- System info and health check scripts deployed
- All Phase 1 deliverables verified and tested"

git push origin main
```

- [ ] Commit created with comprehensive message
- [ ] All changes pushed to GitHub
- [ ] Ready to announce Phase 1 completion

---

## Next Steps (Phase 2)

Phase 2 will add:
- [ ] MQTT broker deployment
- [ ] LoRa module GPIO configuration
- [ ] BLE service implementation
- [ ] API framework initialization

**Estimated start date:** [Date]  
**Estimated completion date:** [Date]

---

**Phase 1 Deployment Checklist**  
**Version:** 1.0  
**Date Completed:** _____________  
**Deployed By:** _____________  
**Hardware Version:** _____________


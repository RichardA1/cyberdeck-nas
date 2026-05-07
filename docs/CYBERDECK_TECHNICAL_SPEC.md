# Cyberdeck Hypermobile NAS - Technical Specification v0.1

**Project Status:** Planning Phase - Awaiting Approval
**Document Version:** 0.1 (Pre-Deployment)
**Last Updated:** May 2026
**License:** GNU General Public License v3.0

---

## 1. Executive Summary

This document describes a low-power, battery-operated, headless NAS server based on the Raspberry Pi 4 platform. The system integrates wireless protocols (WiFi AP/Client, Bluetooth LE, LoRa) for edge computing and data collection. Designed for reproducibility and open-source deployment, every component is documented with BOMs, datasheets, and library references.

**Key Objectives:**
- Minimized power consumption (~5-8W average operation)
- Multiple wireless connectivity options
- Headless server architecture with web/API access
- Reproducible hardware design
- Security-first implementation
- Open-source software stack

---

## 2. System Architecture

### 2.1 Hardware Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CYBERDECK ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐        ┌──────────────┐                   │
│  │ Raspberry Pi │◄──────►│   USB-C Hub  │                   │
│  │      4       │        │  (Power)     │                   │
│  │  (4GB/8GB)   │        └──────────────┘                   │
│  └──────┬───────┘               │                            │
│         │                       ▼                            │
│         │            ┌──────────────────┐                   │
│         │            │  Power Bank      │                   │
│         │            │  30000 mAh       │                   │
│         │            │  (USB-C, 65W)    │                   │
│         │            └──────────────────┘                   │
│         │                                                    │
│    ┌────┴────────────────────────┐                          │
│    ▼                             ▼                           │
│ ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│ │ USB SSD  │  │ LoRa     │  │ TTF      │  │ Real-Time│     │
│ │ 1TB      │  │ Module   │  │ Display  │  │ Clock    │     │
│ │          │  │ (RFM95W) │  │ (3.5")   │  │ (DS3231) │     │
│ └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
│                                                               │
│ Wireless Stack:                                             │
│ • WiFi 5GHz (RPI4 integrated) - AP/Client mode              │
│ • Bluetooth 5.0 (RPI4 integrated) - BLE/Classic             │
│ • LoRa 915MHz (external module) - Long range                │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Software Stack

**Core OS:** Linux (Ubuntu Server 22.04 LTS ARM64 / Raspberry Pi OS Lite 64-bit)

**Services Architecture:**
- **Base OS:** Linux kernel with minimal footprint
- **Wireless:** hostapd, isc-dhcp-server (AP), wpasupplicant (Client)
- **Communication:** Mosquitto MQTT broker, Bleak (BLE), LoRa libraries
- **Web Interface:** Python Flask/FastAPI + SQLite/PostgreSQL
- **Content:** Wiki (MediaWiki Lite or Bookstack), Audio (MPD), Photos (Nextcloud, lightweight)
- **Database:** SQLite (small) or MariaDB (scalable)
- **Automation:** systemd, cron

---

## 3. Detailed Requirements

### 3.1 Functional Requirements

| Requirement | Details |
|---|---|
| **WiFi Host (AP Mode)** | Create network for 5-10 devices, 2.4GHz & 5GHz capable |
| **WiFi Client Mode** | Connect to external networks for backhaul/updates |
| **MQTT Broker** | Host local MQTT for IoT devices, support 50+ clients |
| **BLE Peripheral** | Advertise services for mobile device pairing |
| **LoRa WAN** | Long-range sensor data collection (5+ km line-of-sight) |
| **Web Dashboard** | Access data, manage services, view logs |
| **Media Server** | Stream audio (Music Player Daemon), serve photos |
| **Wiki** | Local documentation storage and retrieval |
| **Database** | Store sensor data, config, metadata |
| **TFT Display** | Status display (IP, services, system health) |
| **Headless Operation** | All management via API/web (display optional) |

### 3.2 Non-Functional Requirements

| Requirement | Target |
|---|---|
| **Power Consumption** | 5-8W average, 2-3W idle, 12-15W peak |
| **Battery Runtime** | 12-36 hours (30000 mAh bank) |
| **Boot Time** | <30 seconds |
| **Uptime** | 99.5% monthly target |
| **Network Latency** | <50ms local, <200ms remote |
| **Storage** | 1TB SSD minimum |
| **Update Cycle** | Monthly security patches |
| **Noise Level** | Passive (fanless operation) |
| **Operating Temp** | 0-40°C |
| **Security** | TLS/SSL, SSH key auth, firewall, OTA updates |

### 3.3 Use Cases

1. **Field Data Collection:** Deploy to remote location, collect sensor data via LoRa, sync to cloud via WiFi backhaul
2. **Local Mesh Network:** Create mesh of cyberdecks communicating via LoRa, WiFi backbone
3. **Media Server:** Portable music/photo library with local WiFi access
4. **Emergency Hotspot:** Offline wiki, emergency communication (BLE + WiFi)
5. **Edge Analytics:** Process sensor data locally, store results in local DB
6. **IoT Gateway:** MQTT broker for smart sensors, local automation

---

## 4. Hardware Bill of Materials (BOM)

### 4.1 Core Computing

| Component | Model | Qty | Cost (USD) | Notes |
|---|---|---|---|---|
| Single Board Computer | Raspberry Pi 4B (8GB) | 1 | $75 | Dual-core WiFi, BT 5.0, 8GB RAM variant |
| Storage | Samsung 870 EVO 1TB | 1 | $60 | SSD via USB3, low power |
| USB-C Hub | Anker 7-in-1 | 1 | $25 | Power delivery, USB3 pass-through |
| SD Card | Samsung 128GB Pro | 1 | $20 | OS boot, can swap for testing |
| **Subtotal** | | | **$180** | |

### 4.2 Wireless Modules

| Component | Model | Qty | Cost (USD) | Notes |
|---|---|---|---|---|
| LoRa Module | RFM95W 915MHz | 1 | $15 | SPI interface, ~100mA active |
| GPIO Breakout | GPIO Hammer Header Kit | 1 | $8 | SPI pinout for LoRa |
| UFL Connector | RP-SMA LoRa Antenna | 1 | $12 | External antenna, 5+ dBi gain |
| **Subtotal** | | | **$35** | |

### 4.3 Power Management

| Component | Model | Qty | Cost (USD) | Notes |
|---|---|---|---|---|
| Power Bank | Anker PowerCore Elite 30000 | 1 | $50 | USB-C PD 65W output, 30000 mAh |
| USB-C Cable | Aukey 6ft E-marker | 2 | $20 | High-quality, certified |
| Power Distribution | PiJuice Zero HAT | 1 | $35 | UPS functionality, battery mgmt (optional) |
| **Subtotal** | | | **$105** | |

### 4.4 Display & Interface

| Component | Model | Qty | Cost (USD) | Notes |
|---|---|---|---|---|
| TFT Display | Adafruit 3.5" PiTFT Plus | 1 | $45 | 480x320, SPI, GPIO attached |
| Tactile Buttons | Momentary switch kit | 5 | $8 | Menu navigation, power button |
| **Subtotal** | | | **$53** | |

### 4.5 Timekeeping & Sensors

| Component | Model | Qty | Cost (USD) | Notes |
|---|---|---|---|---|
| Real-Time Clock | DS3231 I2C Module | 1 | $8 | Coin battery backup, ±2ppm accuracy |
| Temperature Sensor | DHT22 | 1 | $8 | Optional environment monitoring |
| **Subtotal** | | | **$16** | |

### 4.6 Physical Assembly

| Component | Model | Qty | Cost (USD) | Notes |
|---|---|---|---|---|
| Enclosure | Pelican 1450 Case | 1 | $35 | Waterproof, customizable foam |
| Mounting | Aluminum rail system | 1 | $20 | 3D printable or aluminum extrusion |
| Cables/Connectors | Assorted (USB-A, GPIO) | 1 | $30 | Heat shrink, ferrules, spares |
| **Subtotal** | | | **$85** | |

### **4.7 Total Hardware BOM: $474 USD**

**Bill of Materials Summary:**
- Core (RPi4, SSD): $180
- Wireless (LoRa): $35
- Power: $105
- Display: $53
- Sensors: $16
- Assembly: $85

---

## 5. Power Budget Analysis

### 5.1 Current Draw Estimates (at 5V)

| Component | Idle (mA) | Active (mA) | Peak (mA) | Notes |
|---|---|---|---|---|
| Raspberry Pi 4 | 200 | 500 | 800 | CPU/GPU throttled; WiFi active |
| USB SSD (Samsung) | 20 | 150 | 250 | Variable by operation |
| WiFi Module (RPI4) | 0* | 200 | 300 | Integrated, already counted in RPi |
| Bluetooth (RPI4) | 0* | 50 | 100 | Integrated, already counted in RPi |
| LoRa Module (RFM95W) | 1 | 30 | 120 | Rx/Tx cycle, very low idle |
| TFT Display | 5 | 100 | 150 | Backlight intensity dependent |
| DS3231 RTC | 0.5 | 0.5 | 0.5 | Minimal power draw |
| GPIO/Misc | 10 | 20 | 30 | Buttons, sensors |
| **TOTAL** | **237** | **1050** | **1750** | *Integrated in Pi |

### 5.2 Operating Scenarios

| Scenario | Avg Power | Duration | Energy | Notes |
|---|---|---|---|---|
| Headless server (idle) | 1.2W | 24h | 28.8 Wh | Minimal WiFi/Bluetooth scanning |
| Active WiFi AP | 4.5W | 12h | 54 Wh | Full bandwidth, 5-10 clients |
| LoRa TX cycle | 0.6W | 24h | 14.4 Wh | 1 packet/minute pattern |
| Full operation (mixed) | 7W | 8h | 56 Wh | AP + MQTT + Web services |
| Display active | 8.5W | 4h | 34 Wh | Backlight + updates |

### 5.3 Battery Runtime Calculations

**Anker PowerCore Elite 30000 mAh @ 5V:**

```
Capacity: 30000 mAh @ 5V = 150 Wh (nominal)
Efficiency: ~85% (USB-C delivery losses)
Usable: ~127.5 Wh

Scenario Runtime (hours):
- Idle headless: 127.5 Wh / 1.2W = 106 hours (4+ days)
- Mixed operation: 127.5 Wh / 7W = 18 hours
- Full load (unlikely): 127.5 Wh / 8.5W = 15 hours

Practical target: 16-24 hour deployment in field
```

### 5.4 Power Optimization Strategies

1. **CPU Governor:** ondemand/powersave mode for idle periods
2. **WiFi:** Disable 5GHz when not needed, use power-save mode
3. **Display:** Auto-off after 5 minutes, brightness auto-scaling
4. **LoRa:** Duty cycle adherence (EU: 0.1-1%, US: 0.5%)
5. **Bluetooth:** Advertise interval 500ms (reduces scanning overhead)
6. **Services:** Systemd socket activation for on-demand services

---

## 6. Software Stack & Dependencies

### 6.1 Operating System

**Primary:** Ubuntu Server 22.04 LTS (ARM64)
**Alternative:** Raspberry Pi OS Lite 64-bit (Debian-based)

**Rationale:** LTS support, large community, better package availability

**Base Packages:**
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  python3-dev python3-pip \
  git curl wget \
  libffi-dev libssl-dev \
  mosquitto mosquitto-clients \
  hostapd dnsmasq isc-dhcp-server \
  wiringpi pigpio \
  systemd-timesyncd
```

### 6.2 Wireless & Networking

| Protocol | Library/Tool | Version | Purpose |
|---|---|---|---|
| WiFi AP | hostapd | 2.10+ | Access point mode |
| WiFi Client | wpa_supplicant | 2.10+ | Client mode, WLAN mgmt |
| DHCP | isc-dhcp-server | 4.4+ | IP address assignment |
| MQTT | mosquitto | 2.0+ | Message broker |
| BLE | Bleak | 0.21+ | Python BLE client/server |
| LoRa | RPI-LORA (Pico-LoRa) | Latest | SPI interface |

### 6.3 Web Framework & Services

| Service | Library | Version | Purpose |
|---|---|---|---|
| Web API | FastAPI | 0.100+ | Async REST API |
| Database ORM | SQLAlchemy | 2.0+ | DB abstraction |
| Web Server | Gunicorn + Uvicorn | Latest | ASGI server |
| Authentication | Python-jose + bcrypt | Latest | JWT, password hashing |
| Scheduling | APScheduler | 3.10+ | Task scheduling |

### 6.4 Media & Content

| Service | Package | Version | Purpose |
|---|---|---|---|
| Audio Server | Music Player Daemon (MPD) | 0.23+ | Audio streaming |
| Photo Gallery | Gallery-dl or mini-selfhosted | Custom | Photo browsing |
| Wiki | Bookstack or DokuWiki | Lightweight | Markdown documentation |
| Database | SQLite3 / MariaDB | Latest | Data persistence |

### 6.5 Development Tools

```
Language:       Python 3.10+
Build System:   pip, pyenv
Testing:        pytest, pytest-cov
Documentation:  Sphinx, MkDocs
Version Control: Git
CI/CD:          GitHub Actions (optional)
Containerization: Docker (for reproducibility)
```

---

## 7. Security Framework

### 7.1 Network Security

#### WiFi AP Security
- **WPA3-Personal** (fallback: WPA2-PSK)
- **Strong passphrase:** 32+ character random, no defaults
- **SSID:** No device identifiers leaked
- **Frequency:** 2.4GHz only for range; 5GHz optional
- **Isolation:** Client isolation enabled

#### WiFi Client Mode
- Enterprise cert validation (non-self-signed)
- WPA3 preferred, WPA2 fallback
- Disable WiFi scanning when offline

#### MQTT Security
- Broker authentication (username/password)
- TLS/SSL on all connections (mosquitto cert)
- ACL-based topic restrictions
- No anonymous clients

### 7.2 System Security

#### SSH Access
- **Key-only authentication** (no passwords)
- Disable root login
- Custom non-standard port (e.g., 2222)
- Rate limiting via `fail2ban`
- Firewall: UFW with whitelist-only rules

#### User Accounts
- Minimal user (pi/ubuntu) with sudo
- No default passwords
- Automatic password aging (90-day rotation)

#### Filesystem
- **Root filesystem:** ext4 with nodev,nosuid,noexec on /tmp, /var
- **SSD encryption:** LUKS2 optional (minimal overhead)
- **Permissions:** 0700 for sensitive dirs (/home, /root)

### 7.3 Application Security

#### Web API (FastAPI)
- HTTPS/TLS only, HSTS header
- JWT tokens with short TTL (15min)
- Rate limiting (10 req/sec per IP)
- CORS restricted to local subnets
- Input validation & parameterized queries (SQLAlchemy)
- No debug mode in production

#### Authentication
- Bcrypt hashing (cost factor 12)
- Password complexity enforcement (12+ chars, mixed case)
- Account lockout after 5 failed attempts
- Session timeout (30 min inactivity)

### 7.4 Data Protection

- **At rest:** LUKS2 SSD encryption (optional, ~15% perf impact)
- **In transit:** TLS 1.3 for all services
- **Backups:** Encrypted cloud sync (Restic + S3/B2)
- **Secrets:** Environment variables, systemd-creds

### 7.5 Update & Patch Management

- Automated security updates (unattended-upgrades)
- Weekly manual update check
- Rollback capability (A/B SSD imaging)
- CVE monitoring (Dependabot for Python deps)

### 7.6 Monitoring & Logging

- Centralized syslog (optional: Loki/Promtail)
- SSH login alerts (fail2ban + mail)
- Service health checks (systemd-watchdog)
- Disk space alerts (85%+ threshold)
- Failed authentication logging

---

## 8. GitHub Project Structure

```
cyberdeck-nas/
├── README.md                    # Project overview, quick start
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # GNU GPLv3
│
├── docs/
│   ├── TECHNICAL_SPEC.md       # This document (versioned)
│   ├── HARDWARE_ASSEMBLY.md    # Step-by-step build guide
│   ├── POWER_BUDGET.md         # Detailed power analysis
│   ├── SECURITY_HARDENING.md   # Security checklist
│   ├── API_REFERENCE.md        # REST API documentation
│   ├── DEPLOYMENT.md           # Production deployment
│   ├── TROUBLESHOOTING.md      # Common issues & fixes
│   └── datasheets/             # Component PDFs
│
├── hardware/
│   ├── BOM.csv                 # Bill of materials (importable)
│   ├── BOM.xlsx                # Excel version with sourcing
│   ├── schematics/
│   │   ├── pi4_LoRa_gpio.pdf  # GPIO connection diagram
│   │   └── power_mgmt.pdf      # Power distribution schematic
│   ├── 3d-models/
│   │   ├── enclosure/          # Pelican case mounting
│   │   ├── antenna_bracket/    # LoRa antenna mount
│   │   └── display_holder/     # TFT display bracket
│   └── cad/                    # STEP/STL files
│
├── software/
│   ├── system/
│   │   ├── install.sh          # Automated setup script
│   │   ├── wireless_setup.sh   # WiFi AP/Client config
│   │   └── security_harden.sh  # Security lockdown script
│   │
│   ├── api/
│   │   ├── main.py             # FastAPI application
│   │   ├── models.py           # SQLAlchemy ORM models
│   │   ├── routes/
│   │   │   ├── auth.py         # Authentication endpoints
│   │   │   ├── status.py       # System status
│   │   │   ├── mqtt.py         # MQTT management
│   │   │   ├── media.py        # Audio/photo endpoints
│   │   │   └── config.py       # Settings management
│   │   ├── middleware/
│   │   │   ├── auth.py         # JWT middleware
│   │   │   ├── rate_limit.py   # Rate limiting
│   │   │   └── cors.py         # CORS handling
│   │   ├── schemas/
│   │   └── tests/
│   │
│   ├── services/
│   │   ├── mqtt_broker.py      # Mosquitto wrapper
│   │   ├── ble_advertiser.py   # BLE services
│   │   ├── lora_gateway.py     # LoRa packet handling
│   │   ├── media_server.py     # MPD integration
│   │   ├── wiki_server.py      # Wiki service
│   │   └── db_manager.py       # Database operations
│   │
│   ├── ui/
│   │   ├── web_dashboard/      # Vue.js dashboard
│   │   ├── tft_display/        # 3.5" TFT display controller
│   │   └── cli/                # Command-line interface
│   │
│   ├── systemd/
│   │   ├── cyberdeck-api.service
│   │   ├── cyberdeck-mqtt.service
│   │   └── cyberdeck-lora.service
│   │
│   ├── config/
│   │   ├── hostapd.conf.template
│   │   ├── dnsmasq.conf.template
│   │   ├── mosquitto.conf.template
│   │   └── ufw-rules.sh
│   │
│   └── requirements.txt         # Python dependencies
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│
├── docker/
│   ├── Dockerfile              # Container build
│   └── docker-compose.yml      # Service orchestration (dev)
│
├── scripts/
│   ├── backup.sh               # Automated backups
│   ├── update.sh               # Update & patch script
│   ├── health_check.sh         # Diagnostics
│   ├── reset_to_defaults.sh    # Factory reset
│   └── benchmarks/
│       ├── power_test.py       # Power consumption test
│       └── network_test.py     # Performance test
│
├── .github/
│   ├── workflows/
│   │   ├── tests.yml           # CI tests
│   │   ├── docs.yml            # Documentation build
│   │   └── release.yml         # Release automation
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
│
├── .gitignore
├── .env.example                # Environment template
├── pyproject.toml              # Python project config
├── setup.py                    # Package setup
├── Makefile                    # Common tasks
├── VERSION                     # Version number (semver)
└── CHANGELOG.md               # Version history

```

---

## 9. Development Roadmap

### Phase 0: Planning & Approval (Current)
- ✓ Technical specification (this document)
- ✓ Hardware BOM finalization
- ✓ Power budget validation
- GitHub repository creation
- Community feedback collection

### Phase 1: Core Setup (Week 1-2)
- Raspberry Pi OS installation & hardening
- USB SSD setup and boot configuration
- WiFi AP/Client mode testing
- Basic system health monitoring

### Phase 2: Wireless Integration (Week 3-4)
- LoRa module GPIO configuration
- MQTT broker deployment
- BLE advertiser service
- Wireless performance testing

### Phase 3: Web API & Database (Week 5-6)
- FastAPI boilerplate
- SQLite database schema
- Authentication/JWT implementation
- REST endpoint stubs

### Phase 4: Services Integration (Week 7-8)
- Music Player Daemon (MPD) setup
- Wiki (Bookstack/DokuWiki) deployment
- Photo gallery service
- MQTT client integration

### Phase 5: UI & Display (Week 9-10)
- TFT display driver setup
- Web dashboard (Vue.js)
- CLI tools
- Display status screen

### Phase 6: Security Hardening (Week 11-12)
- Firewall configuration
- SSH hardening
- TLS certificate generation
- Security audit & penetration testing

### Phase 7: Testing & Documentation (Week 13-14)
- Unit/integration tests
- Performance benchmarking
- Power consumption validation
- Complete documentation

### Phase 8: Release & Community (Week 15+)
- First stable release (v1.0)
- GitHub Actions CI/CD setup
- Community outreach
- Long-term maintenance plan

---

## 10. Deployment Checklist (Pre-Approval)

### Hardware Planning
- [ ] Component sourcing locations verified (Amazon, Adafruit, AliExpress)
- [ ] Cost estimates confirmed within budget
- [ ] Alternative components identified (substitutions)
- [ ] Datasheet links collected and verified
- [ ] Shipping times accounted for

### Software Planning
- [ ] Python 3.10+ environment confirmed
- [ ] Dependency licenses verified (GPL-compatible)
- [ ] Development tools setup documented
- [ ] Database schema drafted
- [ ] API endpoints outlined

### Security Planning
- [ ] Threat model documented
- [ ] Compliance checklist created (OWASP, CIS)
- [ ] Key management strategy defined
- [ ] Incident response plan outlined
- [ ] Backup/recovery procedures designed

### Community Planning
- [ ] GitHub organization structure finalized
- [ ] Contribution guidelines drafted
- [ ] Code style guide established
- [ ] Commit message format defined
- [ ] Release versioning scheme (semver) confirmed

---

## 11. Approval & Sign-Off

**For deployment to proceed, please confirm:**

1. **Hardware Scope:** Do all components match your vision?
   - [ ] Yes, approved
   - [ ] Changes needed (specify below)

2. **Power Budget:** Are the 12-36 hour runtimes acceptable?
   - [ ] Yes, approved
   - [ ] Need higher capacity (specify hours)
   - [ ] Need lower power (specify W target)

3. **Software Stack:** Do the tools and frameworks fit?
   - [ ] Yes, approved
   - [ ] Prefer alternatives (specify below)

4. **Timeline:** Is 15-week rollout realistic?
   - [ ] Yes, approved
   - [ ] Need faster/slower pace (specify weeks)

5. **Budget:** Is $474 USD hardware cost acceptable?
   - [ ] Yes, approved
   - [ ] Budget constraint (specify max)

6. **Security Level:** Does the security framework meet needs?
   - [ ] Yes, approved
   - [ ] Require higher security (specify areas)

**Please reply with approval or requested changes before we proceed to Phase 1.**

---

## Appendix A: Resources & References

### Raspberry Pi 4 Documentation
- Official: https://www.raspberrypi.org/products/raspberry-pi-4-model-b/
- Datasheet: https://datasheets.raspberrypi.org/rpi4/raspberry-pi-4-datasheet.pdf
- GPIO: https://pinout.xyz/
- Power: https://www.raspberrypi.org/documentation/hardware/raspberrypi/power/

### LoRa Module (RFM95W)
- Datasheet: http://www.hoperf.cn/upload/rfm/RFM95_96_97_98_DataSheet.pdf
- Python Library: https://github.com/Lora-net/LoRaMac-node
- SPI Setup Guide: https://github.com/MCCI-Catena/arduino-lmic

### Display (Adafruit 3.5" PiTFT)
- Product: https://www.adafruit.com/product/2441
- Guide: https://learn.adafruit.com/adafruit-pitft-3-dot-5-plus-480x320-tft-kapacitive-touchscreen
- Library: Adafruit-Python-ILI9341

### Wireless Protocols
- WiFi Hostapd: https://w1.fi/hostapd/
- MQTT Mosquitto: https://mosquitto.org/
- Bluetooth LE Bleak: https://github.com/hbldh/bleak
- LoRaWAN: https://lora-alliance.org/

### Open-Source Software
- Ubuntu Server ARM: https://ubuntu.com/download/raspberry-pi
- FastAPI: https://fastapi.tiangolo.com/
- SQLAlchemy: https://www.sqlalchemy.org/
- Bookstack Wiki: https://www.bookstackapp.com/

### Security References
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks/
- Pi Hardening: https://www.raspberrypi.org/documentation/configuration/security.md

---

**Document Prepared By:** Technical Engineering Team
**Date:** May 2026
**Status:** Awaiting Project Approval


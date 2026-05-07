# Cyberdeck Hypermobile NAS

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Status: Active Development](https://img.shields.io/badge/Status-Active%20Development-brightgreen)]()
[![Platform: Raspberry Pi 4](https://img.shields.io/badge/Platform-Raspberry%20Pi%204-red)]()
[![Python: 3.10+](https://img.shields.io/badge/Python-3.10+-blue)]()

A low-power, battery-operated, headless NAS server with integrated wireless protocols (WiFi AP/Client, Bluetooth LE, LoRa). Designed for edge computing, field data collection, and portable network infrastructure.

**🎯 Key Features:**
- **Low Power:** 5-8W average, 12-36 hour battery runtime
- **Multiple Wireless:** WiFi AP/Client, BLE, 915MHz LoRa
- **Headless Architecture:** API-first, web dashboard, CLI tools
- **Open Source:** Full documentation, reproducible hardware, GPL-3.0 licensed
- **Security-First:** WPA3, TLS/SSL, SSH key-only, automated hardening
- **Media Server:** Audio (MPD), photo gallery, local wiki
- **IoT Gateway:** MQTT broker for sensor networks

---

## 🚀 Quick Start

### Hardware Requirements
- **Raspberry Pi 4B** (8GB recommended)
- **1TB USB SSD** (Samsung 870 EVO or similar)
- **30000 mAh USB-C Power Bank** (65W recommended)
- **RFM95W LoRa Module** (915MHz)
- **3.5" TFT Display** (Adafruit PiTFT Plus)

**Complete BOM:** See [hardware/BOM.csv](hardware/BOM.csv) (~$474 USD)

### Installation (5 minutes)

**1. Flash OS to SD Card:**
```bash
# Download Ubuntu Server 22.04 LTS ARM64 or Raspberry Pi OS Lite 64-bit
# Use Raspberry Pi Imager or Balena Etcher to write to SD card
```

**2. Boot & Connect:**
```bash
# Insert SD card into Pi, power on
# SSH into the device (find IP via router)
ssh ubuntu@<pi-ip>
# Default password: ubuntu (change immediately)
```

**3. Run Automated Setup:**
```bash
wget https://raw.githubusercontent.com/RichardA1/cyberdeck-nas/main/software/system/install.sh
chmod +x install.sh
sudo ./install.sh
```

**4. Configure WiFi AP:**
```bash
sudo /opt/cyberdeck/wireless_setup.sh
# Follow interactive menu to set SSID, passphrase
```

**5. Access Services:**
```
Web API:        http://<pi-ip>:8000/api/v1
Web Dashboard:  http://<pi-ip>:3000
SSH:            ssh cyberdeck@<pi-ip> -p 2222 -i ~/.ssh/id_rsa
```

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────┐
│         CYBERDECK NAS SYSTEM               │
├─────────────────────────────────────────────┤
│                                              │
│  ┌──────────────┐      ┌──────────────┐    │
│  │ Raspberry Pi │      │   Power Bank │    │
│  │      4B      │◄────►│  30000 mAh   │    │
│  │    (8GB)     │      │   USB-C      │    │
│  └──────┬───────┘      └──────────────┘    │
│         │                                    │
│    ┌────┴─────────────┐                    │
│    ▼                  ▼                    │
│ ┌──────────┐    ┌──────────┐              │
│ │ 1TB SSD  │    │ LoRa Mod │              │
│ │USB 3.0   │    │ RFM95W   │              │
│ └──────────┘    └──────────┘              │
│                                              │
│ Services (Systemd):                         │
│ • WiFi AP/Client (hostapd, wpa_supplicant)│
│ • MQTT Broker (mosquitto)                  │
│ • REST API (FastAPI)                       │
│ • BLE Services (Bleak)                     │
│ • LoRa Gateway (custom Python)             │
│ • Media (MPD, wiki, photos)                │
│                                              │
└─────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
cyberdeck-nas/
├── README.md                         # This file
├── CONTRIBUTING.md                   # Development guidelines
├── LICENSE                           # GNU GPLv3
├── VERSION                           # Semantic versioning
│
├── docs/
│   ├── TECHNICAL_SPEC.md            # Complete specifications
│   ├── HARDWARE_ASSEMBLY.md         # Build guide
│   ├── POWER_BUDGET.md              # Power analysis
│   ├── SECURITY_HARDENING.md        # Security checklist
│   ├── API_REFERENCE.md             # REST API docs
│   ├── DEPLOYMENT.md                # Production guide
│   └── TROUBLESHOOTING.md           # Common issues
│
├── hardware/
│   ├── BOM.csv                      # Bill of materials
│   ├── BOM.xlsx                     # Excel with sourcing links
│   ├── schematics/
│   │   ├── pi4_lora_gpio.pdf       # GPIO wiring diagram
│   │   └── power_management.pdf    # Power distribution
│   └── 3d-models/
│       ├── enclosure/               # Pelican case mounts
│       ├── antenna_bracket/         # LoRa antenna
│       └── display_holder/          # TFT display frame
│
├── software/
│   ├── system/
│   │   ├── install.sh               # Automated setup
│   │   ├── wireless_setup.sh        # WiFi AP/Client config
│   │   ├── security_harden.sh       # Security lockdown
│   │   └── health_check.sh          # System diagnostics
│   │
│   ├── api/
│   │   ├── main.py                  # FastAPI app
│   │   ├── models.py                # Database models
│   │   ├── routes/
│   │   │   ├── auth.py              # Authentication
│   │   │   ├── status.py            # System status
│   │   │   └── config.py            # Settings
│   │   ├── middleware/
│   │   ├── tests/
│   │   └── requirements.txt
│   │
│   ├── services/
│   │   ├── mqtt_broker.py
│   │   ├── ble_advertiser.py
│   │   ├── lora_gateway.py
│   │   └── media_server.py
│   │
│   ├── systemd/
│   │   ├── cyberdeck-api.service
│   │   ├── cyberdeck-mqtt.service
│   │   └── cyberdeck-lora.service
│   │
│   ├── config/
│   │   ├── hostapd.conf.template
│   │   ├── mosquitto.conf.template
│   │   └── ufw-rules.sh
│   │
│   └── ui/
│       ├── web_dashboard/
│       └── cli/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│
├── scripts/
│   ├── backup.sh
│   ├── update.sh
│   └── benchmarks/
│
├── .github/
│   ├── workflows/
│   │   ├── tests.yml
│   │   └── docs.yml
│   └── ISSUE_TEMPLATE/
│
└── .gitignore
```

---

## 🔋 Power & Performance

| Scenario | Power | Duration | Notes |
|---|---|---|---|
| **Idle (headless)** | 1.2W | 4+ days | Minimal WiFi scanning |
| **WiFi AP active** | 4.5W | ~30 hours | 5-10 connected clients |
| **Mixed operation** | 7W | 18 hours | AP + API + MQTT |
| **Full load** | 8.5W | 15 hours | All services + display |

**Battery:** Anker PowerCore Elite 30000 mAh (150 Wh, ~85% efficient = 127.5 Wh usable)

---

## 🔐 Security Features

✅ WPA3-Personal WiFi encryption  
✅ MQTT TLS/SSL with ACL  
✅ SSH key-only authentication (no passwords)  
✅ Automated security updates  
✅ Firewall (UFW) with whitelist rules  
✅ HTTPS/TLS for all web services  
✅ JWT token-based API auth  
✅ Bcrypt password hashing (cost 12)  
✅ Rate limiting (10 req/sec per IP)  
✅ Centralized logging & alerts  

See [docs/SECURITY_HARDENING.md](docs/SECURITY_HARDENING.md) for complete hardening guide.

---

## 📚 Documentation

- **[Technical Specification](docs/TECHNICAL_SPEC.md)** - Complete system design
- **[Hardware Assembly](docs/HARDWARE_ASSEMBLY.md)** - Step-by-step build guide
- **[Power Budget](docs/POWER_BUDGET.md)** - Detailed power analysis
- **[API Reference](docs/API_REFERENCE.md)** - REST endpoint documentation
- **[Security Hardening](docs/SECURITY_HARDENING.md)** - Security checklist & procedures
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment instructions
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues & solutions

---

## 🛠️ Development

### Phase 1: Core Setup ✅ (Current)
- Raspberry Pi OS installation & hardening
- USB SSD boot configuration
- WiFi AP/Client mode testing
- Basic system health monitoring

### Phase 2: Wireless Integration (In Progress)
- LoRa module GPIO configuration
- MQTT broker deployment
- BLE advertiser service

### Phase 3-8: Full Stack (Planned)
See [TECHNICAL_SPEC.md](docs/TECHNICAL_SPEC.md#9-development-roadmap) for complete roadmap.

---

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code style guidelines
- Commit message format
- Pull request process
- Development environment setup

**Areas needing help:**
- Hardware testing & validation
- LoRa long-range testing
- Security audits
- Documentation improvements
- Unit test coverage

---

## 📋 Hardware BOM

**Total Cost: ~$474 USD**

| Category | Component | Cost |
|---|---|---|
| **Core** | Raspberry Pi 4B (8GB) | $75 |
| | Samsung 870 EVO 1TB SSD | $60 |
| | USB-C Hub | $25 |
| | SD Card (128GB) | $20 |
| **Wireless** | RFM95W LoRa Module | $15 |
| | LoRa Antenna (UFL) | $12 |
| **Power** | Anker 30000mAh Power Bank | $50 |
| | USB-C Cables (2x) | $20 |
| **Display** | Adafruit 3.5" PiTFT | $45 |
| | Buttons & Switches | $8 |
| **Misc** | RTC Module (DS3231) | $8 |
| | Enclosure & Mounts | $85 |
| | Cables & Connectors | $30 |

See [hardware/BOM.csv](hardware/BOM.csv) for detailed component list with links.

---

## 📊 System Status

```
✅ Phase 1: Core Setup
  ✓ Technical specification complete
  ✓ Hardware BOM finalized
  ✓ GitHub repository initialized
  ➜ Installation scripts (in progress)
  ➜ WiFi configuration templates (in progress)
  ➜ Security hardening (in progress)

⏳ Phase 2: Wireless Integration
⏳ Phase 3: API & Database
⏳ Phase 4-8: Full Stack Implementation
```

---

## 📝 License

GNU General Public License v3.0 - See [LICENSE](LICENSE) file for details.

This project is open-source and free to use, modify, and distribute under GPL-3.0 terms.

---

## 🔗 Useful Links

**Official Resources:**
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [Ubuntu Server ARM64](https://ubuntu.com/download/raspberry-pi)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [MQTT Mosquitto](https://mosquitto.org/)

**Community:**
- [Raspberry Pi Forums](https://www.raspberrypi.org/forums/)
- [LoRa Alliance](https://lora-alliance.org/)
- [OWASP Security](https://owasp.org/)

---

## 📞 Support & Contact

**Issues & Bugs:** [GitHub Issues](https://github.com/RichardA1/cyberdeck-nas/issues)  
**Discussions:** [GitHub Discussions](https://github.com/RichardA1/cyberdeck-nas/discussions)  
**Security:** See [SECURITY.md](SECURITY.md) for responsible disclosure

---

**Last Updated:** May 2026  
**Maintainer:** Richard A. ([@RichardA1](https://github.com/RichardA1))

⭐ If you find this project useful, please star the repo!


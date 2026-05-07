# Contributing to Cyberdeck NAS

Thank you for your interest in contributing to the Cyberdeck NAS project! This document provides guidelines for contributing code, documentation, hardware designs, and other resources.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful, professional, and constructive in all interactions.

---

## Getting Started

### Prerequisites
- **Operating System:** Ubuntu 22.04 LTS ARM64 or Raspberry Pi OS Lite 64-bit
- **Hardware:** Raspberry Pi 4B (2GB minimum, 8GB recommended)
- **Git:** For version control and collaboration
- **Python:** 3.10 or later
- **SSH Keys:** For secure GitHub access

### Fork & Clone
```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/cyberdeck-nas.git
cd cyberdeck-nas

# Add upstream remote
git remote add upstream https://github.com/RichardA1/cyberdeck-nas.git

# Create a feature branch
git checkout -b feature/your-feature-name
```

### Development Environment
```bash
# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r software/api/requirements.txt
pip install -r software/requirements-dev.txt  # Testing tools

# Verify installation
python -m pytest tests/
```

---

## Development Workflow

### Branches

- **main** - Stable release branch (protected)
- **develop** - Integration branch for next release
- **feature/*** - Feature branches (from develop)
- **bugfix/*** - Bug fixes (from develop)
- **docs/*** - Documentation updates (from develop)

### Commit Messages

Follow **Conventional Commits** format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style/formatting (no logic change)
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `test` - Test additions/modifications
- `chore` - Build, dependencies, release tasks
- `ci` - CI/CD configuration

**Examples:**

```bash
# Feature with long body
git commit -m "feat(api): add MQTT device pairing endpoint

Implement new endpoint for BLE device pairing with MQTT broker.
Includes authentication, TLS certificate generation, and ACL rules.

Closes #42
Related: #38"

# Bug fix
git commit -m "fix(wifi): prevent AP/Client mode race condition

Add mutex locking to WiFi interface switching logic to prevent
simultaneous configuration attempts.

Fixes #115"

# Documentation
git commit -m "docs: add power consumption measurement guide

Document procedure for measuring actual power draw using USB meter.
Include scenarios for idle, WiFi AP, and full-load testing."
```

### Pull Request Process

1. **Create feature branch** from `develop`:
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feature/my-feature
   ```

2. **Make changes** with meaningful commits:
   ```bash
   git add .
   git commit -m "feat(component): description"
   ```

3. **Push to your fork**:
   ```bash
   git push origin feature/my-feature
   ```

4. **Create Pull Request** on GitHub:
   - Use PR template
   - Reference related issues
   - Describe changes clearly
   - Include testing instructions

5. **Address review feedback**:
   ```bash
   # Make changes
   git add .
   git commit -m "refactor: address PR feedback"
   git push origin feature/my-feature
   ```

6. **Merge** (maintainer will handle):
   ```bash
   git checkout develop
   git pull upstream develop
   git merge feature/my-feature
   ```

---

## Code Style Guidelines

### Python

**Style:** PEP 8 with Black formatter (line length: 100)

```bash
# Format code
black --line-length=100 software/

# Check style
flake8 software/api --max-line-length=100
pylint software/api
```

**Structure:**
```python
"""Module docstring - brief description."""

import os
import sys
from typing import Optional

import requests
from fastapi import APIRouter, HTTPException

# Constants
MAX_RETRIES = 3
DEFAULT_TIMEOUT = 30

# Functions & Classes
class MyService:
    """Class docstring."""
    
    def __init__(self):
        """Initialize service."""
        self.config = {}
    
    def method(self, param: str) -> Optional[dict]:
        """Method docstring with type hints."""
        if not param:
            raise ValueError("param cannot be empty")
        
        return {"result": param}
```

**Naming:**
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Private members: `_leading_underscore`

### Bash Scripts

**Style:**
```bash
#!/bin/bash
# Script description
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function documentation
my_function() {
    local arg="$1"  # Use local for variables
    echo "Processing: $arg"
}

# Main logic
main() {
    my_function "test"
}

main "$@"
```

### Documentation

**Markdown:**
- Use plain markdown (avoid HTML when possible)
- Consistent heading levels (H1 for title, H2 for sections)
- Code blocks with language specification
- Relative links within repo
- External links in References section

---

## Testing

### Unit Tests

```bash
# Run all tests
pytest tests/

# Run specific test file
pytest tests/unit/test_api.py

# Run with coverage
pytest --cov=software/api tests/
```

**Test structure:**
```python
import pytest
from unittest.mock import Mock, patch
from software.api.models import User

class TestUserModel:
    """Test User ORM model."""
    
    def test_user_creation(self):
        """Test creating new user."""
        user = User(username="testuser", email="test@example.com")
        assert user.username == "testuser"
    
    @patch('software.api.db.session')
    def test_user_save(self, mock_session):
        """Test saving user to database."""
        user = User(username="testuser")
        user.save()
        mock_session.add.assert_called_once_with(user)
```

### Integration Tests

```bash
pytest tests/integration/ -v
```

### Hardware Testing

Include hardware-specific test documentation:
```bash
tests/hardware/
├── test_wifi_connectivity.md
├── test_lora_range.md
├── test_power_consumption.md
└── test_ble_pairing.md
```

---

## Documentation

### Code Comments

Use comments for **why**, not **what**:

```python
# ✓ Good: Explains intent
# Retry with exponential backoff to handle transient network issues
for attempt in range(MAX_RETRIES):
    try:
        result = api.call()
        break
    except ConnectionError:
        time.sleep(2 ** attempt)

# ✗ Bad: Obvious from code
# Increment counter
i += 1
```

### Docstrings

Use Google-style docstrings:

```python
def calculate_battery_runtime(power_draw_w: float, capacity_wh: float) -> float:
    """Calculate battery runtime given power consumption.
    
    Args:
        power_draw_w: Power draw in watts
        capacity_wh: Battery capacity in watt-hours
        
    Returns:
        Runtime in hours (accounting for 85% efficiency loss)
        
    Raises:
        ValueError: If power_draw_w or capacity_wh is negative
        
    Example:
        >>> calculate_battery_runtime(5.0, 150.0)
        25.5
    """
    if power_draw_w < 0 or capacity_wh < 0:
        raise ValueError("Power and capacity must be positive")
    
    efficiency = 0.85
    return (capacity_wh * efficiency) / power_draw_w
```

### README Files

Each directory with significant content should have a README:
- `software/api/README.md` - API documentation
- `software/services/README.md` - Service descriptions
- `hardware/3d-models/README.md` - Model descriptions

---

## Hardware Contributions

### BOM Updates

When adding/updating components:

1. Update `hardware/BOM.csv`:
```csv
Category,Component,Model,Qty,Cost_USD,Source,Link,Notes
Core,SBC,Raspberry Pi 4B (8GB),1,75,Adafruit,https://...,Dual WiFi recommended
Wireless,LoRa,RFM95W,1,15,AliExpress,https://...,915MHz variant
```

2. Include datasheet link in `hardware/datasheets/`

3. Update technical spec: `docs/TECHNICAL_SPEC.md`

4. Document in commit:
```bash
git commit -m "hardware: add ultrasonic sensor to BOM

Added HC-SR04 ultrasonic distance sensor for optional proximity detection.
- Model: HC-SR04 (40kHz, 4m range)
- Cost: $2 USD
- Interface: GPIO (Trig/Echo)
- Rationale: Enable autonomous charging dock detection"
```

### Schematic & CAD Files

- **Schematics:** PDF format with layer descriptions
- **3D Models:** STEP format (CAD) + STL (3D print)
- **Documentation:** Include assembly notes, tolerances, materials

---

## Issue Reporting

### Bug Reports

Use the bug report template and include:

1. **System Information:**
   - OS: Ubuntu 22.04 / Raspberry Pi OS
   - Python version
   - Hardware (Pi model, RAM, components)

2. **Steps to Reproduce:**
   ```
   1. Connect LoRa module
   2. Run: python -m software.services.lora_gateway
   3. Observe error
   ```

3. **Expected vs Actual:**
   - Expected: Gateway initializes successfully
   - Actual: SPI initialization fails with error

4. **Error Output:**
   ```
   Traceback (most recent call last):
   ...
   ```

### Feature Requests

Include:
- **Use case:** Why is this feature needed?
- **Proposed solution:** How should it work?
- **Alternatives:** Other approaches considered?
- **Impact:** Affects power, performance, security?

---

## Release Process

### Version Numbering

Use **Semantic Versioning** (MAJOR.MINOR.PATCH):
- `MAJOR`: Breaking changes
- `MINOR`: New features (backward compatible)
- `PATCH`: Bug fixes

Example: `v1.2.3`

### Release Checklist

1. **Update version:**
   ```bash
   echo "1.2.3" > VERSION
   ```

2. **Update CHANGELOG.md:**
   ```markdown
   ## [1.2.3] - 2026-05-15
   
   ### Added
   - LoRa gateway support
   - BLE device pairing
   
   ### Fixed
   - WiFi reconnection race condition
   
   ### Security
   - Updated SSL certificates
   ```

3. **Commit & Tag:**
   ```bash
   git add VERSION CHANGELOG.md
   git commit -m "chore: release v1.2.3"
   git tag -a v1.2.3 -m "Release version 1.2.3"
   git push origin main v1.2.3
   ```

---

## Recognition

We value all contributions! Contributors will be:
- Listed in `CONTRIBUTORS.md`
- Mentioned in release notes
- Credited in project README

---

## Questions?

- **General:** Open a Discussion on GitHub
- **Technical:** Open an Issue with details
- **Security:** See SECURITY.md for responsible disclosure
- **Maintenance:** Contact [@RichardA1](https://github.com/RichardA1)

---

**Thank you for contributing to Cyberdeck NAS!** 🚀


# 🕵️ Deep JavaScript Recon Tool

**Author:** spiX-7  
**Version:** 2.0  
**Purpose:** Advanced JavaScript reconnaissance, API endpoint discovery, and sensitive data extraction for penetration testing and bug bounty hunting.

---

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Test Commands](#test-commands)
- [Output Files](#output-files)
- [Tool Workflow](#tool-workflow)
- [Legal Disclaimer](#legal-disclaimer)

---

## ✨ Features

### Core Capabilities

- **Subdomain Enumeration:** Multi-source subdomain discovery (subfinder, assetfinder, amass)
- **Active Host Detection:** HTTP probing with technology detection
- **Deep JS Discovery:** 6 different methods to find JavaScript files
- **JS File Download:** Automatic download and storage of all JS files
- **Secret Extraction:** 40+ regex patterns for API keys, tokens, passwords
- **API Endpoint Discovery:** Extract all API endpoints and paths
- **Sensitive Data Mining:** Find emails, IPs, subdomains, comments
- **Automated Vulnerability Scanning:** Nuclei integration for security checks
- **Detailed Reporting:** Comprehensive HTML and text reports

### What It Finds

✅ API Keys (AWS, Google, Stripe, etc.)  
✅ Authentication Tokens & Secrets  
✅ Database Credentials  
✅ API Endpoints & Paths  
✅ Hidden Subdomains  
✅ Email Addresses  
✅ Internal IPs  
✅ TODO/FIXME Comments  
✅ Webhook URLs  
✅ Firebase Configs  

---

## 🛠️ Installation

### Prerequisites

- **Operating System:** Linux (Kali, Ubuntu, Parrot) or macOS
- **Requirements:** Bash, Go, Python3, curl, git

### Step 1: Install Go (if not installed)

```bash
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### Step 2: Install Required Tools

```bash
# Subdomain enumeration tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install github.com/owasp-amass/amass/v4/...@master

# HTTP probing
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# URL/JS discovery
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/hakluke/hakrawler@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest

# JS extraction
go install github.com/003random/getJS@latest
go install github.com/lc/subjs@latest

# Link finder
git clone https://github.com/GerbenJavado/LinkFinder.git
cd LinkFinder
python3 setup.py install
cd ..

# Vulnerability scanning
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
nuclei -update-templates

# Utility tools
go install -v github.com/tomnomnom/anew@latest
go install github.com/tomnomnom/unfurl@latest

# Install jq (JSON processor)
sudo apt install jq -y  # Debian/Ubuntu
# or
brew install jq  # macOS
```

### Step 3: Verify Installation

```bash
# Check all tools are installed
subfinder -version
assetfinder -h
amass -version
httpx -version
waybackurls -h
gau -h
hakrawler -h
katana -version
getJS -h
subjs -h
nuclei -version
anew -h
unfurl -h
jq --version
```

### Step 4: Download the Script

```bash
# Create directory
mkdir ~/tools
cd ~/tools

# Download the script
git clone https://github.com/SpiX-7/Recon-pro.git
# Or create manually and paste the code

# Make executable
chmod +x jsrecon.sh

# Add to PATH (optional)
sudo cp jsrecon.sh /usr/local/bin/jsrecon
```

---

## 🚀 Usage

### Basic Usage

```bash
./jsrecon.sh <target_domain>
```

### Examples

```bash
# Basic scan
./jsrecon.sh example.com

# Real-world targets for testing (if authorized)
./jsrecon.sh tesla.com
./jsrecon.sh hackerone.com
./jsrecon.sh bugcrowd.com
```

### Output Structure

```
jsrecon_example.com_20241223_143022/
├── REPORT.txt                    # Main report
├── all_subdomains.txt           # All discovered subdomains
├── active_hosts.txt             # Live hosts
├── all_js_files.txt             # All JS file URLs
├── js_files/                    # Downloaded JS files
│   ├── abc123.js
│   ├── def456.js
│   └── ...
├── secrets_found.txt            # API keys, tokens, passwords
├── api_endpoints.txt            # API endpoints discovered
├── all_urls_found.txt           # All URLs extracted
├── emails_found.txt             # Email addresses
├── ips_found.txt                # IP addresses
├── subdomains_found.txt         # Subdomains from JS
├── sensitive_comments.txt       # TODO/FIXME comments
├── nuclei_results.txt           # Vulnerability scan results
└── js_filename_map.txt          # Mapping of files to URLs
```

---

## 🧪 Test Commands

### Test 1: Quick Test (Small Target)

```bash
./jsrecon.sh example.com
```

**Expected Output:**
- Subdomains: 5-20
- Active Hosts: 3-10
- JS Files: 10-50
- Time: 2-5 minutes

### Test 2: Medium Target

```bash
./jsrecon.sh tesla.com
```

**Expected Output:**
- Subdomains: 100-500
- Active Hosts: 50-200
- JS Files: 200-1000
- Time: 10-20 minutes

### Test 3: Large Target

```bash
./jsrecon.sh google.com
```

**Expected Output:**
- Subdomains: 1000+
- Active Hosts: 500+
- JS Files: 5000+
- Time: 30-60 minutes

### Test 4: Check Specific Output

```bash
# Run scan
./jsrecon.sh example.com

# Check results
cd jsrecon_example.com_*/

# View report
cat REPORT.txt

# Check secrets
cat secrets_found.txt | head -20

# Check API endpoints
cat api_endpoints.txt | head -20

# Count JS files
ls -1 js_files/ | wc -l

# Search for specific patterns
grep -i "api_key" secrets_found.txt
grep -i "password" secrets_found.txt
grep -i "token" secrets_found.txt
```

### Test 5: Validate Tool Installation

```bash
# Run tool check
./jsrecon.sh --check

# Or manually check each tool
which subfinder assetfinder amass httpx waybackurls gau hakrawler katana getJS subjs nuclei anew unfurl jq
```

---

## 📊 Tool Workflow

```
┌─────────────────────────────────────────────────────┐
│              INPUT: target.com                      │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 1: Subdomain Enumeration                     │
│  • subfinder → passive DNS                          │
│  • assetfinder → certificate transparency           │
│  • amass → multiple sources                         │
│  Output: all_subdomains.txt                         │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 2: Active Host Detection                     │
│  • httpx → probe all subdomains                     │
│  • detect technologies, status codes                │
│  Output: active_hosts.txt                           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 3: Deep JS Discovery                         │
│  • waybackurls → historical URLs                    │
│  • gau → aggregate URL sources                      │
│  • hakrawler → spider active sites                  │
│  • katana → smart JS extraction                     │
│  • getJS → dedicated JS finder                      │
│  • subjs → subdomain JS files                       │
│  Output: all_js_files.txt                           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 4: Download JS Files                         │
│  • curl each JS file                                │
│  • save with unique hash names                      │
│  Output: js_files/ directory                        │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 5: Secret Extraction                         │
│  • 40+ regex patterns                               │
│  • API keys, tokens, passwords                      │
│  • AWS keys, Firebase configs                       │
│  Output: secrets_found.txt                          │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 6: API Endpoint Extraction                   │
│  • /api/* paths                                     │
│  • /v1/, /v2/ versioned APIs                        │
│  • /graphql endpoints                               │
│  Output: api_endpoints.txt                          │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 7: Sensitive Data Mining                     │
│  • emails, IPs, subdomains                          │
│  • TODO/FIXME comments                              │
│  Output: emails_found.txt, ips_found.txt            │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 8: Nuclei Vulnerability Scan                 │
│  • scan JS files for known issues                   │
│  Output: nuclei_results.txt                         │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 9: Generate Report                           │
│  Output: REPORT.txt                                 │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Common Use Cases

### Bug Bounty Hunting

```bash
# Run full scan
./jsrecon.sh target.com

# Focus on high-value findings
grep -i "secret\|key\|token" jsrecon_*/secrets_found.txt

# Test API endpoints
cat jsrecon_*/api_endpoints.txt | httpx -mc 200,201,401,403
```

### Penetration Testing

```bash
# Full reconnaissance
./jsrecon.sh client-domain.com

# Manual JS analysis
cd jsrecon_*/js_files
grep -r "eval\|innerHTML\|document.write" .
```

### Security Research

```bash
# Multiple targets
for domain in target1.com target2.com target3.com; do
    ./jsrecon.sh $domain
done
```

---

## 🔍 Advanced Techniques

### Find AWS Keys

```bash
grep -E "AKIA[0-9A-Z]{16}" jsrecon_*/secrets_found.txt
```

### Find Google API Keys

```bash
grep -E "AIza[0-9A-Za-z\-_]{35}" jsrecon_*/secrets_found.txt
```

### Find Internal IPs

```bash
grep -E "10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\." jsrecon_*/ips_found.txt
```

### Extract S3 Buckets

```bash
grep -i "s3.amazonaws.com\|s3-.*\.amazonaws\.com" jsrecon_*/all_urls_found.txt
```

---

## ⚠️ Legal Disclaimer

**IMPORTANT:** This tool is designed for **authorized security testing only**.

### Legal Use Only

- ✅ Only scan domains you **own** or have **written permission** to test
- ✅ Use on **bug bounty programs** with proper scope
- ✅ Use in **authorized penetration testing engagements**
- ❌ **DO NOT** scan targets without permission
- ❌ **DO NOT** use for malicious purposes

### Responsible Disclosure

If you find vulnerabilities:

1. **DO NOT** exploit them
2. **DO NOT** share them publicly
3. **DO** report to the vendor/bug bounty program
4. **DO** follow responsible disclosure practices

### Laws and Regulations

Unauthorized access to computer systems is **illegal** in most countries:

- USA: Computer Fraud and Abuse Act (CFAA)
- UK: Computer Misuse Act
- EU: NIS Directive
- International: Council of Europe Convention on Cybercrime

**The author (spiX-7) is NOT responsible for misuse of this tool.**

---

## 📝 Troubleshooting

### Tool Not Found Error

```bash
# Error: subfinder: command not found
# Solution: Check Go PATH
echo $PATH | grep go/bin
export PATH=$PATH:~/go/bin
```

### Permission Denied

```bash
# Error: Permission denied
# Solution: Make script executable
chmod +x jsrecon.sh
```

### No Subdomains Found

```bash
# Check if domain is valid
host example.com

# Try manual subfinder test
subfinder -d example.com
```

### Slow Performance

```bash
# Reduce threads in script
# Edit line with httpx: -threads 20 (instead of 50)
# Edit line with gau: --threads 5 (instead of 10)
```

---

## 🤝 Contributing

Found a bug? Have a feature request?

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## 📧 Contact

**Author:** spiX-7  
**Purpose:** Educational and authorized security testing  

---

## 📄 License

This tool is provided "as is" for educational and authorized security testing purposes only.

---

**Remember: With great power comes great responsibility. Use ethically! 🛡️**

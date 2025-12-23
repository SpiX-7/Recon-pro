#!/bin/bash

# ============================================
# Deep JavaScript Recon & Secret Hunter
# Author: spiX-7
# Purpose: Deep dive JS analysis and sensitive data extraction
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

banner() {
    echo -e "${BLUE}"
    echo "  ███████╗██████╗ ██╗██╗  ██╗     ███████╗"
    echo "  ██╔════╝██╔══██╗██║╚██╗██╔╝     ╚════██║"
    echo "  ███████╗██████╔╝██║ ╚███╔╝█████╗   ██╔╝"
    echo "  ╚════██║██╔═══╝ ██║ ██╔██╗╚════╝  ██╔╝ "
    echo "  ███████║██║     ██║██╔╝ ██╗       ██║  "
    echo "  ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝       ╚═╝  "
    echo -e "${NC}"
    echo -e "${GREEN}[+] Deep JavaScript Recon Tool v2.0 - spiX-7${NC}"
    echo -e "${CYAN}[+] JS Files → Secrets → API Endpoints → Sensitive Data${NC}"
    echo ""
}

check_tools() {
    echo -e "${YELLOW}[*] Checking required tools...${NC}"
    
    TOOLS=(
        "subfinder" "assetfinder" "amass" "httpx"
        "waybackurls" "gau" "hakrawler" "katana"
        "getJS" "subjs" "nuclei" "curl" "jq"
        "anew" "unfurl" "grep" "sed" "linkfinder"
    )
    
    MISSING=()
    
    for tool in "${TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            MISSING+=("$tool")
            echo -e "${RED}[-] $tool not found${NC}"
        else
            echo -e "${GREEN}[+] $tool found${NC}"
        fi
    done
    
    if [ ${#MISSING[@]} -ne 0 ]; then
        echo -e "${YELLOW}[!] Missing tools: ${MISSING[*]}${NC}"
        echo -e "${CYAN}[*] Check README.md for installation${NC}"
        exit 1
    fi
}

subdomain_enum() {
    DOMAIN=$1
    OUTPUT_DIR=$2
    
    echo -e "${MAGENTA}[•] PHASE 1: Subdomain Enumeration${NC}"
    
    echo -e "${YELLOW}[*] Running subfinder...${NC}"
    subfinder -d "$DOMAIN" -all -silent -o "$OUTPUT_DIR/subfinder.txt" 2>/dev/null
    
    echo -e "${YELLOW}[*] Running assetfinder...${NC}"
    assetfinder --subs-only "$DOMAIN" > "$OUTPUT_DIR/assetfinder.txt" 2>/dev/null
    
    echo -e "${YELLOW}[*] Running amass passive...${NC}"
    amass enum -passive -d "$DOMAIN" -o "$OUTPUT_DIR/amass.txt" 2>/dev/null
    
    cat "$OUTPUT_DIR/subfinder.txt" "$OUTPUT_DIR/assetfinder.txt" "$OUTPUT_DIR/amass.txt" 2>/dev/null | sort -u | anew "$OUTPUT_DIR/all_subdomains.txt" >/dev/null
    
    echo -e "${GREEN}[✓] Found $(wc -l < "$OUTPUT_DIR/all_subdomains.txt") subdomains${NC}"
}

check_alive() {
    INPUT=$1
    OUTPUT=$2
    
    echo -e "${MAGENTA}[•] PHASE 2: Active Host Detection${NC}"
    
    cat "$INPUT" | httpx -silent -o "$OUTPUT" \
        -status-code -title -tech-detect \
        -threads 50 -timeout 10 -random-agent
    
    echo -e "${GREEN}[✓] Found $(wc -l < "$OUTPUT") active hosts${NC}"
}

deep_js_discovery() {
    INPUT=$1
    OUTPUT_DIR=$2
    
    echo -e "${MAGENTA}[•] PHASE 3: Deep JS File Discovery${NC}"
    
    echo -e "${YELLOW}[*] Crawling with waybackurls...${NC}"
    cat "$INPUT" | waybackurls | grep -iE "\.js(\?|$)" | anew "$OUTPUT_DIR/wayback_js.txt" >/dev/null
    
    echo -e "${YELLOW}[*] Crawling with gau...${NC}"
    cat "$INPUT" | gau --threads 10 | grep -iE "\.js(\?|$)" | anew "$OUTPUT_DIR/gau_js.txt" >/dev/null
    
    echo -e "${YELLOW}[*] Deep crawling with hakrawler...${NC}"
    cat "$INPUT" | hakrawler -d 5 -u -js | grep -iE "\.js(\?|$)" | anew "$OUTPUT_DIR/hakrawler_js.txt" >/dev/null
    
    echo -e "${YELLOW}[*] Smart crawling with katana...${NC}"
    cat "$INPUT" | katana -silent -jc -jsl -kf all -d 5 | grep -iE "\.js(\?|$)" | anew "$OUTPUT_DIR/katana_js.txt" >/dev/null
    
    echo -e "${YELLOW}[*] Using getJS extractor...${NC}"
    getJS --input "$INPUT" --complete --output "$OUTPUT_DIR/getjs.txt" 2>/dev/null
    
    echo -e "${YELLOW}[*] Using subjs extractor...${NC}"
    cat "$INPUT" | subjs | anew "$OUTPUT_DIR/subjs.txt" >/dev/null
    
    cat "$OUTPUT_DIR"/*_js.txt "$OUTPUT_DIR/getjs.txt" "$OUTPUT_DIR/subjs.txt" 2>/dev/null | sort -u > "$OUTPUT_DIR/all_js_files.txt"
    
    echo -e "${GREEN}[✓] Collected $(wc -l < "$OUTPUT_DIR/all_js_files.txt") JS files${NC}"
}

download_js_files() {
    JS_LIST=$1
    OUTPUT_DIR=$2
    
    echo -e "${MAGENTA}[•] PHASE 4: Downloading JS Files${NC}"
    
    mkdir -p "$OUTPUT_DIR/js_files"
    
    COUNTER=0
    while IFS= read -r url; do
        ((COUNTER++))
        filename=$(echo "$url" | md5sum | cut -d' ' -f1)
        
        echo -ne "\r${YELLOW}[*] Downloading: $COUNTER files${NC}"
        
        curl -sk -A "Mozilla/5.0" "$url" -o "$OUTPUT_DIR/js_files/$filename.js" 2>/dev/null
        
        if [ -s "$OUTPUT_DIR/js_files/$filename.js" ]; then
            echo "$url" >> "$OUTPUT_DIR/downloaded_js_map.txt"
            echo "$filename.js|$url" >> "$OUTPUT_DIR/js_filename_map.txt"
        else
            rm -f "$OUTPUT_DIR/js_files/$filename.js"
        fi
    done < "$JS_LIST"
    
    echo ""
    echo -e "${GREEN}[✓] Downloaded $(ls -1 "$OUTPUT_DIR/js_files" 2>/dev/null | wc -l) JS files${NC}"
}

extract_secrets() {
    OUTPUT_DIR=$1
    
    echo -e "${MAGENTA}[•] PHASE 5: Secret & Sensitive Data Extraction${NC}"
    
    SECRET_PATTERNS=(
        "api[_-]?key"
        "apikey"
        "api[_-]?secret"
        "access[_-]?key"
        "secret[_-]?key"
        "client[_-]?secret"
        "client[_-]?id"
        "consumer[_-]?key"
        "consumer[_-]?secret"
        "auth[_-]?token"
        "access[_-]?token"
        "refresh[_-]?token"
        "bearer[_-]?token"
        "session[_-]?token"
        "oauth"
        "password"
        "passwd"
        "pwd"
        "private[_-]?key"
        "ssh[_-]?key"
        "aws[_-]?access"
        "aws[_-]?secret"
        "s3[_-]?bucket"
        "firebase"
        "credentials"
        "database[_-]?url"
        "db[_-]?pass"
        "db[_-]?user"
        "mysql"
        "postgres"
        "mongodb"
        "redis[_-]?pass"
        "stripe[_-]?key"
        "twilio"
        "sendgrid"
        "mailgun"
        "slack[_-]?token"
        "webhook"
        "AKIA[0-9A-Z]{16}"
        "[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com"
        "AIza[0-9A-Za-z\\-_]{35}"
    )
    
    echo -e "${YELLOW}[*] Scanning for API keys and secrets...${NC}"
    
    for pattern in "${PATTERNS[@]}"; do
        grep -rHinE "$pattern" "$OUTPUT_DIR/js_files/" 2>/dev/null | anew "$OUTPUT_DIR/secrets_raw.txt" >/dev/null
    done
    
    if [ -f "$OUTPUT_DIR/secrets_raw.txt" ]; then
        sort -u "$OUTPUT_DIR/secrets_raw.txt" > "$OUTPUT_DIR/secrets_found.txt"
        echo -e "${GREEN}[✓] Found $(wc -l < "$OUTPUT_DIR/secrets_found.txt") potential secrets${NC}"
    else
        echo -e "${YELLOW}[!] No secrets found${NC}"
        touch "$OUTPUT_DIR/secrets_found.txt"
    fi
}

extract_api_endpoints() {
    OUTPUT_DIR=$1
    
    echo -e "${MAGENTA}[•] PHASE 6: API Endpoint Extraction${NC}"
    
    echo -e "${YELLOW}[*] Extracting API endpoints...${NC}"
    
    grep -rhoE "(https?://[^\"'> ]+/api[^\"'> ]*)" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u > "$OUTPUT_DIR/api_endpoints.txt"
    
    grep -rhoE "(/api[/a-zA-Z0-9_?&=\-\.]*)" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u >> "$OUTPUT_DIR/api_endpoints.txt"
    
    grep -rhoE "(/v[0-9]+/[a-zA-Z0-9_/?&=\-\.]*)" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u >> "$OUTPUT_DIR/api_endpoints.txt"
    
    grep -rhoE "(/graphql[/a-zA-Z0-9_?&=\-\.]*)" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u >> "$OUTPUT_DIR/api_endpoints.txt"
    
    sort -u "$OUTPUT_DIR/api_endpoints.txt" -o "$OUTPUT_DIR/api_endpoints.txt"
    
    echo -e "${GREEN}[✓] Extracted $(wc -l < "$OUTPUT_DIR/api_endpoints.txt") API endpoints${NC}"
}

extract_urls() {
    OUTPUT_DIR=$1
    
    echo -e "${YELLOW}[*] Extracting all URLs...${NC}"
    
    grep -rhoE "(https?://[a-zA-Z0-9./?=_&%:#-]*)" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u > "$OUTPUT_DIR/all_urls_found.txt"
    
    grep -rhoE "(/[a-zA-Z0-9_/?=&%:#.-]*)" "$OUTPUT_DIR/js_files/" 2>/dev/null | grep -v "^//$" | sort -u > "$OUTPUT_DIR/all_paths_found.txt"
    
    echo -e "${GREEN}[✓] Extracted $(wc -l < "$OUTPUT_DIR/all_urls_found.txt") URLs${NC}"
    echo -e "${GREEN}[✓] Extracted $(wc -l < "$OUTPUT_DIR/all_paths_found.txt") paths${NC}"
}

extract_sensitive_info() {
    OUTPUT_DIR=$1
    
    echo -e "${YELLOW}[*] Searching for sensitive comments...${NC}"
    grep -rn "//.*TODO\|//.*FIXME\|//.*HACK\|//.*XXX\|//.*BUG" "$OUTPUT_DIR/js_files/" > "$OUTPUT_DIR/sensitive_comments.txt" 2>/dev/null
    
    echo -e "${YELLOW}[*] Searching for email addresses...${NC}"
    grep -rhoE "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u > "$OUTPUT_DIR/emails_found.txt"
    
    echo -e "${YELLOW}[*] Searching for IP addresses...${NC}"
    grep -rhoE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u > "$OUTPUT_DIR/ips_found.txt"
    
    echo -e "${YELLOW}[*] Searching for subdomains...${NC}"
    grep -rhoE "[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}" "$OUTPUT_DIR/js_files/" 2>/dev/null | sort -u > "$OUTPUT_DIR/subdomains_found.txt"
    
    echo -e "${GREEN}[✓] Extracted sensitive information${NC}"
}

run_nuclei_scan() {
    OUTPUT_DIR=$1
    
    echo -e "${MAGENTA}[•] PHASE 7: Nuclei Security Scan${NC}"
    
    if [ -f "$OUTPUT_DIR/all_js_files.txt" ]; then
        echo -e "${YELLOW}[*] Running nuclei on JS files...${NC}"
        nuclei -l "$OUTPUT_DIR/all_js_files.txt" -t exposures/ -severity low,medium,high,critical -o "$OUTPUT_DIR/nuclei_results.txt" -silent 2>/dev/null
        
        if [ -s "$OUTPUT_DIR/nuclei_results.txt" ]; then
            echo -e "${GREEN}[✓] Nuclei found $(wc -l < "$OUTPUT_DIR/nuclei_results.txt") issues${NC}"
        else
            echo -e "${YELLOW}[!] No vulnerabilities found by nuclei${NC}"
        fi
    fi
}

generate_report() {
    OUTPUT_DIR=$1
    TARGET=$2
    
    echo -e "${MAGENTA}[•] PHASE 8: Generating Report${NC}"
    
    REPORT="$OUTPUT_DIR/REPORT.txt"
    
    cat > "$REPORT" << EOF
╔════════════════════════════════════════════════════════════╗
║          Deep JavaScript Reconnaissance Report             ║
║                    by spiX-7                               ║
╚════════════════════════════════════════════════════════════╝

[+] Target: $TARGET
[+] Scan Date: $(date)
[+] Report Directory: $OUTPUT_DIR

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[•] SUMMARY

Subdomains Found: $(wc -l < "$OUTPUT_DIR/all_subdomains.txt" 2>/dev/null || echo "0")
Active Hosts: $(wc -l < "$OUTPUT_DIR/active_hosts.txt" 2>/dev/null || echo "0")
JavaScript Files: $(wc -l < "$OUTPUT_DIR/all_js_files.txt" 2>/dev/null || echo "0")
Downloaded JS: $(ls -1 "$OUTPUT_DIR/js_files" 2>/dev/null | wc -l || echo "0")
API Endpoints: $(wc -l < "$OUTPUT_DIR/api_endpoints.txt" 2>/dev/null || echo "0")
Secrets Found: $(wc -l < "$OUTPUT_DIR/secrets_found.txt" 2>/dev/null || echo "0")
URLs Extracted: $(wc -l < "$OUTPUT_DIR/all_urls_found.txt" 2>/dev/null || echo "0")
Emails Found: $(wc -l < "$OUTPUT_DIR/emails_found.txt" 2>/dev/null || echo "0")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[•] KEY FILES

$(ls -lh "$OUTPUT_DIR"/*.txt 2>/dev/null | awk '{print $9" - "$5}')

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[•] NEXT STEPS

1. Review secrets_found.txt for sensitive data
2. Test API endpoints from api_endpoints.txt
3. Check emails_found.txt for potential targets
4. Analyze nuclei_results.txt for vulnerabilities
5. Review js_files/ directory for manual analysis

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

    echo -e "${GREEN}[✓] Report generated: $REPORT${NC}"
    cat "$REPORT"
}

main() {
    banner
    
    if [ $# -eq 0 ]; then
        echo -e "${RED}[!] Usage: $0 <target_domain>${NC}"
        echo -e "${CYAN}[*] Example: $0 example.com${NC}"
        echo -e "${CYAN}[*] Example: $0 tesla.com${NC}"
        exit 1
    fi
    
    TARGET=$1
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR="jsrecon_${TARGET}_${TIMESTAMP}"
    
    mkdir -p "$OUTPUT_DIR"
    
    check_tools
    
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ Target: ${TARGET}${NC}"
    echo -e "${BLUE}║ Output: ${OUTPUT_DIR}${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    subdomain_enum "$TARGET" "$OUTPUT_DIR"
    check_alive "$OUTPUT_DIR/all_subdomains.txt" "$OUTPUT_DIR/active_hosts.txt"
    deep_js_discovery "$OUTPUT_DIR/active_hosts.txt" "$OUTPUT_DIR"
    download_js_files "$OUTPUT_DIR/all_js_files.txt" "$OUTPUT_DIR"
    extract_secrets "$OUTPUT_DIR"
    extract_api_endpoints "$OUTPUT_DIR"
    extract_urls "$OUTPUT_DIR"
    extract_sensitive_info "$OUTPUT_DIR"
    run_nuclei_scan "$OUTPUT_DIR"
    generate_report "$OUTPUT_DIR" "$TARGET"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           SCAN COMPLETE - spiX-7                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}[+] Check $OUTPUT_DIR/REPORT.txt for full details${NC}"
}

main "$@"

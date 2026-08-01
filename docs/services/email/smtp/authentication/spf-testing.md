---
title: "SPF Testing and Validation"
description: "Validating SPF records with command-line tools, online validators, and automated checks"
author: "Joseph Streeter"
tags: ["email", "authentication", "spf", "testing", "validation", "dig"]
category: "services"
last_updated: "2026-08-01"
---
## SPF Testing and Validation

Verify a record before publishing it, and keep verifying it afterwards — SPF breaks
silently when an included provider changes their record.

### SPF Testing and Validation

Thorough testing ensures your SPF configuration works correctly before deployment and helps identify issues in production.

#### Command-Line Testing

**Basic SPF Query:**

```bash
# Query SPF record
dig +short TXT example.com
```

**Expected output (SPF record exists):**

```text
"v=spf1 mx include:_spf.google.com -all"
```

**Expected output (No SPF record):**

```text
[No output - record doesn't exist]
```

**Detailed DNS Queries:**

```bash
# Query specific DNS server
dig @8.8.8.8 TXT example.com
```

**Expected output:**

```text
;; ANSWER SECTION:
example.com.        3600    IN      TXT     "v=spf1 mx include:_spf.google.com -all"
```

```bash
# Verbose output with full trace
dig TXT example.com +trace

# Check for multiple TXT records
dig TXT example.com +short | grep -i spf
```

**Expected output (multiple TXT records):**

```text
"v=spf1 mx include:_spf.google.com -all"
```

**Validate Included Records:**

```bash
# Check included SPF records
dig +short TXT _spf.google.com
```

**Expected output:**

```text
"v=spf1 include:_netblocks.google.com include:_netblocks2.google.com include:_netblocks3.google.com ~all"
```

```bash
# Verify MX records referenced in SPF
dig +short MX example.com
```

**Expected output:**

```text
10 mail.example.com.
20 mail2.example.com.
```

```bash
# Check A records
dig +short A mail.example.com
```

**Expected output:**

```text
192.0.2.10
```

#### Practical Testing Scenarios

##### Scenario 1: Test from Known Good IP

```bash
# 1. Identify your mail server IP
dig +short A mail.example.com
# Output: 192.0.2.10

# 2. Verify this IP is in your SPF record
dig +short TXT example.com
# Output: "v=spf1 ip4:192.0.2.0/24 -all"

# 3. Send test email and verify headers
echo "SPF Test from authorized server" | mail -s "SPF Test" test@gmail.com
```

##### Scenario 2: Verify Third-Party Service**

```bash
# 1. Check your SPF includes third-party
dig +short TXT example.com
# Output: "v=spf1 include:_spf.google.com -all"

# 2. Verify third-party SPF exists
dig +short TXT _spf.google.com
# Output: "v=spf1 include:_netblocks.google.com ..."

# 3. Send test via Google Workspace
# Use Google Workspace webmail to send test message
```

##### Scenario 3: Test SPF Failures

**Test Case 1: Syntax Error (PermError):**

```bash
# Intentional syntax error in SPF record (for testing environment only)
# Record: "v=spf1 mx include :_spf.google.com -all"  # Space before colon
dig +short TXT test-broken.example.com
```

**Expected output:**

```text
"v=spf1 mx include :_spf.google.com -all"
```

**Expected authentication header:**

```text
Authentication-Results: mx.google.com;
  spf=permerror (google.com: error in processing during lookup of test-broken.example.com: invalid SPF record)
  smtp.mailfrom=sender@test-broken.example.com
```

**Test Case 2: Too Many DNS Lookups (PermError):**

```bash
# SPF record exceeding 10 lookup limit
# Record with 12+ includes/mx/a mechanisms
dig +short TXT test-overlimit.example.com
```

**Expected authentication header:**

```text
Authentication-Results: mx.outlook.com;
  spf=permerror (sender IP is 192.0.2.10)
  smtp.mailfrom=sender@test-overlimit.example.com;
  reason="SPF exceeds DNS lookup limit"
```

**Test Case 3: Unauthorized Sender (Fail):**

```bash
# Send from server NOT in SPF record
# Sending IP: 203.0.113.50
# SPF Record: "v=spf1 ip4:192.0.2.0/24 -all"
```

**Expected authentication header:**

```text
Authentication-Results: mx.gmail.com;
  spf=fail (google.com: domain of sender@example.com does not designate 203.0.113.50 as permitted sender)
  smtp.mailfrom=sender@example.com;
  smtp.helo=unauthorized-mail.badhost.com
```

**Test Case 4: Soft Fail:**

```bash
# SPF record with ~all (soft fail)
# Sending IP: 203.0.113.50
# SPF Record: "v=spf1 ip4:192.0.2.0/24 ~all"
```

**Expected authentication header:**

```text
Authentication-Results: mx.yahoo.com;
  spf=softfail (transitioning 203.0.113.50)
  smtp.mailfrom=sender@example.com
```

**Test Case 5: No SPF Record (None):**

```bash
# Domain with no SPF record
dig +short TXT no-spf-record.example.com
```

**Expected output:**

```text
[No SPF record returned]
```

**Expected authentication header:**

```text
Authentication-Results: mx.example.com;
  spf=none (no SPF record)
  smtp.mailfrom=sender@no-spf-record.example.com
```

#### Automated Testing Script

```bash
#!/bin/bash
# SPF Validation Test Script with Error Handling
# Usage: ./spf-test.sh <domain> <test-email>

set -euo pipefail  # Exit on error, undefined variables, pipe failures

DOMAIN=${1:-}
TEST_EMAIL=${2:-}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

if [ -z "$DOMAIN" ]; then
    error_exit "Usage: $0 <domain> <test-email>"
fi

echo "===== SPF Testing for $DOMAIN ====="
echo

# 1. Check SPF record exists
echo "1. Checking SPF record..."
SPF_RECORD=$(dig +short TXT "$DOMAIN" | grep -i "^\"v=spf1" | tr -d '"' || true)

if [ -z "$SPF_RECORD" ]; then
    error_exit "No SPF record found for $DOMAIN!"
fi

success "SPF Record found: $SPF_RECORD"
echo

# 2. Validate SPF syntax
echo "2. Validating SPF syntax..."

# Check for common syntax errors
if [[ ! "$SPF_RECORD" =~ ^v=spf1[[:space:]] ]]; then
    error_exit "SPF record must start with 'v=spf1 '"
fi

if [[ ! "$SPF_RECORD" =~ ([-~+?]all|redirect=) ]]; then
    warning "SPF record should end with a terminating 'all' mechanism or redirect"
fi

# Check for multiple spf records (not allowed)
SPF_COUNT=$(dig +short TXT "$DOMAIN" | grep -c "v=spf1" || true)
if [ "$SPF_COUNT" -gt 1 ]; then
    error_exit "Multiple SPF records found! Only one SPF record is allowed per domain."
fi

success "SPF syntax is valid"
echo

# 3. Count DNS lookups
echo "3. Counting DNS lookups..."

# Count mechanisms that cause DNS lookups
INCLUDES=$(echo "$SPF_RECORD" | grep -o "include:[^ ]*" | wc -l)
MX_COUNT=$(echo "$SPF_RECORD" | grep -o "\\bmx\\b" | wc -l)
A_COUNT=$(echo "$SPF_RECORD" | grep -o -E " a\\b|\\ba:" | wc -l)
PTR_COUNT=$(echo "$SPF_RECORD" | grep -o "\\bptr\\b" | wc -l)
EXISTS_COUNT=$(echo "$SPF_RECORD" | grep -o "exists:" | wc -l)

echo "  Includes: $INCLUDES"
echo "  MX mechanisms: $MX_COUNT"
echo "  A mechanisms: $A_COUNT"
echo "  PTR mechanisms: $PTR_COUNT"
echo "  EXISTS mechanisms: $EXISTS_COUNT"

TOTAL=$((INCLUDES + MX_COUNT + A_COUNT + PTR_COUNT + EXISTS_COUNT))
echo "  Estimated total lookups: $TOTAL"

if [ "$TOTAL" -gt 10 ]; then
    error_exit "SPF record exceeds 10 DNS lookup limit! This will cause PermError."
elif [ "$TOTAL" -eq 10 ]; then
    warning "SPF record uses exactly 10 DNS lookups. No room for expansion."
elif [ "$TOTAL" -ge 8 ]; then
    warning "SPF record uses $TOTAL DNS lookups. Approaching the 10 lookup limit."
else
    success "DNS lookup count is within limits ($TOTAL/10)"
fi

if [ "$PTR_COUNT" -gt 0 ]; then
    warning "PTR mechanism is deprecated and slow. Consider replacing with ip4/ip6."
fi

echo

# 4. Check record length
echo "4. Checking record length..."
LENGTH=${#SPF_RECORD}
echo "  Record length: $LENGTH characters"

if [ "$LENGTH" -gt 450 ]; then
    error_exit "Record length exceeds 450 characters. May cause issues with some DNS servers."
elif [ "$LENGTH" -gt 255 ]; then
    warning "Record length exceeds 255 character soft limit ($LENGTH characters)"
else
    success "Record length is acceptable"
fi
echo

# 5. Check for common issues
echo "5. Checking for common issues..."

# Check for soft fail in production
if [[ "$SPF_RECORD" =~ ~all$ ]]; then
    warning "Using soft fail (~all). Consider hard fail (-all) for production."
fi

# Check for overly permissive policies
if [[ "$SPF_RECORD" =~ [?]all$ ]]; then
    warning "Using neutral (?all). This provides no protection!"
fi

if [[ "$SPF_RECORD" =~ [+]all$ ]]; then
    warning "Using pass (+all). This allows ALL servers - completely insecure!"
fi

# Check for hardcoded IPs from major providers
if echo "$SPF_RECORD" | grep -qE "ip4:(168\.245\.|167\.89\.)"; then
    warning "Possible hardcoded SendGrid IPs. Use include:sendgrid.net instead."
fi

success "Common issue check complete"
echo

# 6. Test included SPF records
echo "6. Validating included SPF records..."
INCLUDE_DOMAINS=$(echo "$SPF_RECORD" | grep -o "include:[^ ]*" | cut -d':' -f2 || true)

if [ -n "$INCLUDE_DOMAINS" ]; then
    for INCLUDE_DOMAIN in $INCLUDE_DOMAINS; do
        echo "  Checking $INCLUDE_DOMAIN..."
        INCLUDE_SPF=$(dig +short TXT "$INCLUDE_DOMAIN" | grep "v=spf1" || true)
        if [ -z "$INCLUDE_SPF" ]; then
            error_exit "Included domain $INCLUDE_DOMAIN has no SPF record!"
        else
            success "$INCLUDE_DOMAIN has valid SPF record"
        fi
    done
else
    echo "  No includes to validate"
fi
echo

# 7. Send test email (optional)
if [ -n "$TEST_EMAIL" ]; then
    echo "7. Sending test email to $TEST_EMAIL..."
    if command -v mail >/dev/null 2>&1; then
        echo "SPF test from $DOMAIN at $(date)" | mail -s "SPF Test - $DOMAIN" "$TEST_EMAIL" && \
        success "Test email sent successfully" || \
        warning "Failed to send test email"
        echo "Check authentication headers in received message for:"
        echo "  Authentication-Results: ... spf=pass ..."
    else
        warning "mail command not found. Skipping email test."
        echo "Install mailutils: sudo apt-get install mailutils"
    fi
else
    echo "7. Skipping test email (no recipient specified)"
fi
echo

echo "===== Test Complete ====="
echo
echo "Summary:"
echo "  Domain: $DOMAIN"
echo "  SPF Record: $SPF_RECORD"
echo "  DNS Lookups: $TOTAL/10"
echo "  Record Length: $LENGTH characters"
echo

exit 0
```

**Script features:**

- ✅ Comprehensive error handling with `set -euo pipefail`
- ✅ Color-coded output for errors, warnings, and success
- ✅ Validates SPF syntax and common issues
- ✅ Counts DNS lookups accurately
- ✅ Checks included SPF records
- ✅ Provides actionable warnings
- ✅ Exit codes for CI/CD integration

**Usage:**

```bash
# Basic validation
./spf-test.sh example.com

# With test email
./spf-test.sh example.com admin@example.com

# In CI/CD pipeline
./spf-test.sh example.com || exit 1
```

#### CI/CD Integration Examples

##### GitHub Actions Workflow

```yaml
name: SPF Validation

on:
  push:
    paths:
      - 'dns/spf-records.txt'
      - '.github/workflows/spf-validation.yml'
  pull_request:
    paths:
      - 'dns/spf-records.txt'

jobs:
  validate-spf:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install dig
        run: sudo apt-get update && sudo apt-get install -y dnsutils
      
      - name: Download SPF validation script
        run: |
          curl -o spf-test.sh https://example.com/scripts/spf-test.sh
          chmod +x spf-test.sh
      
      - name: Validate SPF records
        run: |
          # Read domains from file
          while IFS= read -r domain; do
            echo "Testing $domain..."
            ./spf-test.sh "$domain" || exit 1
          done < dns/spf-records.txt
      
      - name: Check DNS lookup count
        run: |
          # Fail if any domain exceeds 8 lookups (warning threshold)
          while IFS= read -r domain; do
            LOOKUPS=$(dig +short TXT "$domain" | \
              grep -o -E "include:|\\bmx\\b|\\ba\\b" | wc -l)
            if [ "$LOOKUPS" -gt 8 ]; then
              echo "ERROR: $domain uses $LOOKUPS lookups (max safe: 8)"
              exit 1
            fi
          done < dns/spf-records.txt
      
      - name: Notify on failure
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '❌ SPF validation failed! Check workflow logs for details.'
            })
```

##### GitLab CI Pipeline

```yaml
spf-validation:
  stage: test
  image: alpine:latest
  before_script:
    - apk add --no-cache bind-tools bash
  script:
    - chmod +x scripts/spf-test.sh
    - |
      for domain in $(cat dns/spf-records.txt); do
        echo "Validating $domain..."
        ./scripts/spf-test.sh "$domain" || exit 1
      done
  rules:
    - changes:
      - dns/spf-records.txt
      - scripts/spf-test.sh
  allow_failure: false
```

#### Pre-Commit Hook for SPF Validation

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook for SPF validation

set -e

SPF_RECORDS_FILE="dns/spf-records.txt"

# Only run if SPF records file is being committed
if git diff --cached --name-only | grep -q "$SPF_RECORDS_FILE"; then
    echo "Validating SPF records before commit..."
    
    # Get list of domains from staged file
    DOMAINS=$(git show ":$SPF_RECORDS_FILE")
    
    # Validate each domain
    for domain in $DOMAINS; do
        echo "Checking $domain..."
        
        # Check if SPF record exists
        SPF=$(dig +short TXT "$domain" | grep "v=spf1" || true)
        if [ -z "$SPF" ]; then
            echo "ERROR: No SPF record found for $domain"
            exit 1
        fi
        
        # Count DNS lookups
        LOOKUPS=$(echo "$SPF" | grep -o -E "include:|\\bmx\\b|\\ba\\b" | wc -l)
        if [ "$LOOKUPS" -gt 10 ]; then
            echo "ERROR: $domain exceeds DNS lookup limit ($LOOKUPS lookups)"
            exit 1
        fi
        
        echo "✓ $domain: $LOOKUPS/10 lookups"
    done
    
    echo "✓ All SPF records validated successfully"
fi

exit 0
```

**Make hook executable:**

```bash
chmod +x .git/hooks/pre-commit
```

#### Automated SPF Monitoring Script

```bash
#!/bin/bash
# Continuous SPF monitoring script
# Run via cron: */15 * * * * /usr/local/bin/spf-monitor.sh

DOMAINS="example.com example.org"
ALERT_EMAIL="admin@example.com"
LOG_FILE="/var/log/spf-monitor.log"

for DOMAIN in $DOMAINS; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check SPF record
    SPF=$(dig +short TXT "$DOMAIN" +timeout=5 | grep "v=spf1" || true)
    
    if [ -z "$SPF" ]; then
        # SPF record missing!
        echo "[$TIMESTAMP] ALERT: No SPF record for $DOMAIN" >> "$LOG_FILE"
        echo "ALERT: SPF record missing for $DOMAIN" | \
            mail -s "SPF ALERT: $DOMAIN" "$ALERT_EMAIL"
    else
        # Check lookup count
        LOOKUPS=$(echo "$SPF" | grep -o -E "include:|\\bmx\\b|\\ba\\b" | wc -l)
        
        if [ "$LOOKUPS" -gt 10 ]; then
            echo "[$TIMESTAMP] ALERT: $DOMAIN exceeds lookup limit ($LOOKUPS)" >> "$LOG_FILE"
            echo "ALERT: $DOMAIN SPF exceeds lookup limit: $LOOKUPS lookups" | \
                mail -s "SPF ALERT: $DOMAIN" "$ALERT_EMAIL"
        fi
        
        echo "[$TIMESTAMP] OK: $DOMAIN SPF valid ($LOOKUPS lookups)" >> "$LOG_FILE"
    fi
done
```

**Install as cron job:**

```bash
# Edit crontab
crontab -e

# Add monitoring every 15 minutes
*/15 * * * * /usr/local/bin/spf-monitor.sh
```

#### Online SPF Validators

Use these tools for comprehensive validation:

**MXToolbox SPF Record Check:**

- URL: <https://mxtoolbox.com/spf.aspx>
- Features: Syntax validation, DNS lookup counting, error detection
- Shows: All mechanisms, includes, and potential issues

**Kitterman SPF Validator:**

- URL: <https://www.kitterman.com/spf/validate.html>
- Features: Record syntax checking, policy simulation
- Test: Specific IP addresses against your SPF record

**DMARC Analyzer SPF Check:**

- URL: <https://www.dmarcanalyzer.com/spf/checker/>
- Features: Comprehensive analysis, recommendations
- Reports: DNS lookup count, syntax errors, best practices

**What These Tools Check:**

- ✅ Syntax correctness
- ✅ DNS lookup count (must be ≤10)
- ✅ Nested includes and their impact
- ✅ Record length
- ✅ Common misconfigurations
- ✅ Qualifier usage (-, ~, +, ?)
- ✅ Mechanism ordering
- ✅ Proper termination (all mechanism)

#### Email Header Analysis

After sending test emails, examine the authentication headers:

**Successful SPF Pass:**

```text
Authentication-Results: mx.google.com;
  spf=pass (google.com: domain of sender@example.com designates 192.0.2.10 as permitted sender)
  smtp.mailfrom=sender@example.com
  smtp.helo=mail.example.com
```

**SPF Failure:**

```text
Authentication-Results: mx.gmail.com;
  spf=fail (google.com: domain of example.com does not designate 203.0.113.50 as permitted sender)
  smtp.mailfrom=sender@example.com
```

**SPF SoftFail:**

```text
Authentication-Results: mx.outlook.com;
  spf=softfail (sender IP is 198.51.100.25)
  smtp.mailfrom=sender@example.com
```

**What to Look For:**

- `spf=pass` - Configuration working correctly
- `spf=fail` - Sending server not authorized
- `spf=softfail` - Using ~all, sender probably unauthorized
- `spf=neutral` - No policy assertion (using ?all)
- `spf=none` - No SPF record found
- `spf=temperror` - Temporary DNS failure
- `spf=permerror` - SPF record syntax error or too many lookups

#### Testing Checklist

Before deploying SPF to production, verify:

- [ ] SPF record exists and is syntactically correct
- [ ] DNS lookup count is under 10
- [ ] Record length is under 255 characters
- [ ] All mail servers are authorized (mx, ip4/ip6, include)
- [ ] Third-party services included correctly
- [ ] Test emails pass from all sending sources
- [ ] Headers show `spf=pass` for legitimate email
- [ ] Policy (-all vs ~all) is appropriate for current stage
- [ ] Subdomain SPF records configured
- [ ] Monitoring is in place for SPF failures

## Related Topics

- [Email Authentication Overview](index.md)
- [SPF (Sender Policy Framework)](spf.md)
- [SPF Subdomain Protection and Attack Vectors](spf-security.md)
- [SPF Testing and Validation](spf-testing.md)
- [SPF Troubleshooting and Migration](spf-troubleshooting.md)
- [DKIM (DomainKeys Identified Mail)](dkim.md)
- [DKIM Testing and Troubleshooting](dkim-testing.md)
- [DKIM Key Rotation and Operations](dkim-operations.md)
- [DMARC (Domain-based Message Authentication)](dmarc.md)
- [DMARC Reports and Analysis](dmarc-reports.md)
- [DMARC Policy Rollout](dmarc-rollout.md)
- [DMARC Testing and Troubleshooting](dmarc-testing.md)

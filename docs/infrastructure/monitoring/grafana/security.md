---
title: Security Configuration
description: Comprehensive security guide for Grafana and Prometheus including TLS, authentication, secrets management, and hardening
author: Your Name
ms.author: your-email
ms.topic: security
ms.date: 12/30/2025
keywords: security, tls, mtls, authentication, oauth, ldap, secrets management, hardening
uid: docs.infrastructure.grafana.security
---

This guide covers implementing production-grade security for your Grafana and Prometheus monitoring stack including TLS/mTLS, authentication, authorization, secrets management, and security hardening.

## TLS/SSL Configuration

### Generate Self-Signed Certificates (Development)

```bash
#!/bin/bash
# generate-certs.sh

# Create certificates directory
mkdir -p certs
cd certs

# Generate CA private key and certificate
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 3650 -key ca-key.pem -out ca-cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=Monitoring-CA"

# Generate server private key
openssl genrsa -out server-key.pem 4096

# Create server certificate signing request
openssl req -new -key server-key.pem -out server-csr.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=prometheus.example.com"

# Create server certificate extensions
cat > server-ext.cnf <<EOF
subjectAltName = DNS:prometheus.example.com,DNS:grafana.example.com,DNS:alertmanager.example.com,IP:192.168.1.100
extendedKeyUsage = serverAuth
EOF

# Sign server certificate
openssl x509 -req -days 365 -in server-csr.pem -CA ca-cert.pem \
  -CAkey ca-key.pem -CAcreateserial -out server-cert.pem \
  -extfile server-ext.cnf

# Generate client private key
openssl genrsa -out client-key.pem 4096

# Create client certificate signing request
openssl req -new -key client-key.pem -out client-csr.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=monitoring-client"

# Create client certificate extensions
cat > client-ext.cnf <<EOF
extendedKeyUsage = clientAuth
EOF

# Sign client certificate
openssl x509 -req -days 365 -in client-csr.pem -CA ca-cert.pem \
  -CAkey ca-key.pem -CAcreateserial -out client-cert.pem \
  -extfile client-ext.cnf

# Set proper permissions
chmod 600 *-key.pem
chmod 644 *-cert.pem

echo "Certificates generated successfully in ./certs directory"
```

### Let's Encrypt Certificates (Production)

```bash
#!/bin/bash
# Setup Let's Encrypt with Certbot

# Install certbot
sudo apt-get update
sudo apt-get install -y certbot

# Generate certificates
sudo certbot certonly --standalone \
  -d prometheus.example.com \
  -d grafana.example.com \
  -d alertmanager.example.com \
  --email admin@example.com \
  --agree-tos \
  --no-eff-email

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Copy certificates for Docker
sudo cp /etc/letsencrypt/live/grafana.example.com/fullchain.pem ./certs/
sudo cp /etc/letsencrypt/live/grafana.example.com/privkey.pem ./certs/
sudo chown 1000:1000 ./certs/*.pem
```

### Prometheus TLS Configuration

Update `docker-compose.yml`:

```yaml
services:
  prometheus:
    image: prom/prometheus:v2.48.1
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.config.file=/etc/prometheus/web-config.yml'  # TLS config
    volumes:
      - ./prometheus/web-config.yml:/etc/prometheus/web-config.yml:ro
      - ./certs:/etc/prometheus/certs:ro
```

Create `/etc/prometheus/web-config.yml`:

```yaml
tls_server_config:
  cert_file: /etc/prometheus/certs/server-cert.pem
  key_file: /etc/prometheus/certs/server-key.pem
  client_ca_file: /etc/prometheus/certs/ca-cert.pem
  client_auth_type: RequireAndVerifyClientCert  # mTLS

basic_auth_users:
  prometheus: $2y$10$abcdefghijklmnopqrstuv  # bcrypt hashed password
  admin: $2y$10$1234567890abcdefghijkl

# HTTP/2 configuration
http_server_config:
  http2: true
```

Generate bcrypt password hash:

```bash
# Install htpasswd
sudo apt-get install apache2-utils

# Generate bcrypt hash
htpasswd -nBC 10 "" | tr -d ':\n'
# Enter password when prompted, copy the hash
```

### Grafana TLS Configuration

Update `grafana.ini`:

```ini
[server]
protocol = https
http_addr = 0.0.0.0
http_port = 3000
cert_file = /etc/grafana/certs/server-cert.pem
cert_key = /etc/grafana/certs/server-key.pem
domain = grafana.example.com
root_url = https://grafana.example.com

[security]
cookie_secure = true
cookie_samesite = strict
strict_transport_security = true
strict_transport_security_max_age_seconds = 31536000
strict_transport_security_preload = true
strict_transport_security_subdomains = true
content_security_policy = true
x_content_type_options = true
x_xss_protection = true
```

Update `docker-compose.yml`:

```yaml
services:
  grafana:
    image: grafana/grafana:10.2.3
    volumes:
      - ./grafana/grafana.ini:/etc/grafana/grafana.ini:ro
      - ./certs:/etc/grafana/certs:ro
```

### Alertmanager TLS Configuration

Create `/etc/alertmanager/web-config.yml`:

```yaml
tls_server_config:
  cert_file: /etc/alertmanager/certs/server-cert.pem
  key_file: /etc/alertmanager/certs/server-key.pem
  client_ca_file: /etc/alertmanager/certs/ca-cert.pem
  client_auth_type: RequireAndVerifyClientCert

basic_auth_users:
  alertmanager: $2y$10$hashedPasswordHere
```

Update `docker-compose.yml`:

```yaml
services:
  alertmanager:
    image: prom/alertmanager:v0.26.0
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--web.config.file=/etc/alertmanager/web-config.yml'
    volumes:
      - ./alertmanager/web-config.yml:/etc/alertmanager/web-config.yml:ro
      - ./certs:/etc/alertmanager/certs:ro
```

## Authentication and Authorization

### Grafana Basic Authentication

Already enabled by default with secure password:

```ini
[auth.basic]
enabled = true

[security]
admin_user = admin
admin_password = $__file{/run/secrets/grafana_admin_password}
```

### Grafana OAuth Integration

#### GitHub OAuth

```ini
[auth.github]
enabled = true
allow_sign_up = true
client_id = ${GITHUB_CLIENT_ID}
client_secret = $__file{/run/secrets/github_client_secret}
scopes = user:email,read:org
auth_url = https://github.com/login/oauth/authorize
token_url = https://github.com/login/oauth/access_token
api_url = https://api.github.com/user
allowed_organizations = your-org
team_ids = 123456,789012
role_attribute_path = contains(groups[*], 'admins') && 'Admin' || contains(groups[*], 'editors') && 'Editor' || 'Viewer'
```

#### Google OAuth

```ini
[auth.google]
enabled = true
allow_sign_up = true
client_id = ${GOOGLE_CLIENT_ID}
client_secret = $__file{/run/secrets/google_client_secret}
scopes = https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email
auth_url = https://accounts.google.com/o/oauth2/auth
token_url = https://accounts.google.com/o/oauth2/token
api_url = https://www.googleapis.com/oauth2/v1/userinfo
allowed_domains = example.com
hosted_domain = example.com
```

#### Azure AD OAuth

```ini
[auth.azuread]
enabled = true
allow_sign_up = true
client_id = ${AZURE_CLIENT_ID}
client_secret = $__file{/run/secrets/azure_client_secret}
scopes = openid email profile
auth_url = https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/authorize
token_url = https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token
allowed_groups = group-id-1,group-id-2
role_attribute_path = contains(groups[*], 'admin-group-id') && 'Admin' || contains(groups[*], 'editor-group-id') && 'Editor' || 'Viewer'
```

### Grafana LDAP Integration

Create `/etc/grafana/ldap.toml`:

```toml
[[servers]]
host = "ldap.example.com"
port = 636
use_ssl = true
start_tls = false
ssl_skip_verify = false
root_ca_cert = "/etc/grafana/certs/ca-cert.pem"
client_cert = "/etc/grafana/certs/client-cert.pem"
client_key = "/etc/grafana/certs/client-key.pem"

bind_dn = "cn=grafana,ou=services,dc=example,dc=com"
bind_password = '$__file{/run/secrets/ldap_bind_password}'

timeout = 10

# User search filter
search_filter = "(uid=%s)"
search_base_dns = ["ou=users,dc=example,dc=com"]

# Group search filter
group_search_filter = "(&(objectClass=posixGroup)(memberUid=%s))"
group_search_base_dns = ["ou=groups,dc=example,dc=com"]
group_search_filter_user_attribute = "uid"

[servers.attributes]
name = "givenName"
surname = "sn"
username = "uid"
member_of = "memberOf"
email = "mail"

# Admin group mapping
[[servers.group_mappings]]
group_dn = "cn=grafana-admins,ou=groups,dc=example,dc=com"
org_role = "Admin"
grafana_admin = true

# Editor group mapping
[[servers.group_mappings]]
group_dn = "cn=grafana-editors,ou=groups,dc=example,dc=com"
org_role = "Editor"
grafana_admin = false

# Viewer group mapping
[[servers.group_mappings]]
group_dn = "cn=grafana-viewers,ou=groups,dc=example,dc=com"
org_role = "Viewer"
grafana_admin = false

# Default role for authenticated users
[[servers.group_mappings]]
group_dn = "*"
org_role = "Viewer"
```

Enable LDAP in `grafana.ini`:

```ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true
sync_cron = "0 0 * * *"  # Sync at midnight
active_sync_enabled = true
```

### Prometheus Authentication

#### Basic Authentication for Scrape Targets

Update `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'secure-app'
    static_configs:
      - targets: ['app.example.com:9090']
    basic_auth:
      username: 'prometheus'
      password_file: /run/secrets/app_scrape_password

  - job_name: 'secure-app-with-tls'
    static_configs:
      - targets: ['app.example.com:9090']
    scheme: https
    tls_config:
      ca_file: /etc/prometheus/certs/ca-cert.pem
      cert_file: /etc/prometheus/certs/client-cert.pem
      key_file: /etc/prometheus/certs/client-key.pem
      insecure_skip_verify: false
    basic_auth:
      username: 'prometheus'
      password_file: /run/secrets/app_scrape_password
```

#### OAuth2 Authentication

```yaml
scrape_configs:
  - job_name: 'oauth2-app'
    static_configs:
      - targets: ['app.example.com:9090']
    oauth2:
      client_id: 'prometheus-client'
      client_secret_file: /run/secrets/oauth_client_secret
      token_url: 'https://auth.example.com/oauth/token'
      scopes:
        - 'metrics:read'
```

## Secrets Management

### Docker Secrets (Recommended for Docker Swarm)

```yaml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:10.2.3
    environment:
      - GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password
      - GF_DATABASE_PASSWORD__FILE=/run/secrets/postgres_password
    secrets:
      - grafana_admin_password
      - postgres_password
      - smtp_password

secrets:
  grafana_admin_password:
    file: ./secrets/grafana_admin_password.txt
  postgres_password:
    file: ./secrets/postgres_password.txt
  smtp_password:
    file: ./secrets/smtp_password.txt
```

### HashiCorp Vault Integration

#### Install Vault

```bash
# Install Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault

# Start Vault in dev mode (for testing)
vault server -dev

# Set environment variables
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root-token'
```

#### Store Secrets in Vault

```bash
# Enable KV secrets engine
vault secrets enable -path=monitoring kv-v2

# Store Grafana admin password
vault kv put monitoring/grafana admin_password="SecurePassword123!"

# Store Prometheus credentials
vault kv put monitoring/prometheus scrape_password="PromPass123!"

# Store SMTP credentials
vault kv put monitoring/smtp password="SMTPPass123!" username="alerts@example.com"

# Read secrets
vault kv get monitoring/grafana
```

#### Retrieve Secrets in Docker Compose

Create `get-secrets.sh`:

```bash
#!/bin/bash
set -e

# Ensure Vault is accessible
if ! vault status &>/dev/null; then
  echo "Error: Cannot connect to Vault"
  exit 1
fi

# Create secrets directory
mkdir -p secrets
chmod 700 secrets

# Retrieve and store secrets
vault kv get -field=admin_password monitoring/grafana > secrets/grafana_admin_password.txt
vault kv get -field=scrape_password monitoring/prometheus > secrets/prometheus_scrape_password.txt
vault kv get -field=password monitoring/smtp > secrets/smtp_password.txt

# Set proper permissions
chmod 600 secrets/*

echo "Secrets retrieved successfully"
```

Run before starting containers:

```bash
./get-secrets.sh
docker compose up -d
```

### Kubernetes Secrets (For Kubernetes Deployments)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-secrets
  namespace: monitoring
type: Opaque
stringData:
  admin-password: "SecurePassword123!"
  smtp-password: "SMTPPass123!"
---
apiVersion: v1
kind: Secret
metadata:
  name: prometheus-secrets
  namespace: monitoring
type: Opaque
stringData:
  scrape-password: "PromPass123!"
```

Mount secrets in deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  template:
    spec:
      containers:
        - name: grafana
          image: grafana/grafana:10.2.3
          env:
            - name: GF_SECURITY_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: grafana-secrets
                  key: admin-password
```

### Sealed Secrets (Kubernetes)

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Install kubeseal CLI
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# Create sealed secret
echo -n "SecurePassword123!" | kubectl create secret generic grafana-admin-password \
  --dry-run=client \
  --from-file=password=/dev/stdin \
  -o yaml | \
  kubeseal -o yaml > grafana-sealed-secret.yaml

# Apply sealed secret
kubectl apply -f grafana-sealed-secret.yaml
```

## Network Security

### Docker Network Isolation

```yaml
version: '3.8'

services:
  prometheus:
    networks:
      - monitoring
      - scrape-targets

  grafana:
    networks:
      - monitoring
      - frontend

  private-app:
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
    internal: true  # No external access
  scrape-targets:
    driver: bridge
  frontend:
    driver: bridge
```

### Firewall Rules (UFW)

```bash
#!/bin/bash
# configure-firewall.sh

# Enable UFW
sudo ufw enable

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTPS for Grafana (via reverse proxy)
sudo ufw allow 443/tcp

# Allow Prometheus only from specific IPs
sudo ufw allow from 192.168.1.0/24 to any port 9090 proto tcp comment 'Prometheus'

# Allow Grafana only from specific IPs
sudo ufw allow from 192.168.1.0/24 to any port 3000 proto tcp comment 'Grafana'

# Allow Node Exporter from Prometheus servers
sudo ufw allow from 192.168.1.100 to any port 9100 proto tcp comment 'Node Exporter from Prometheus'

# Deny all other traffic
sudo ufw default deny incoming

# Show status
sudo ufw status numbered
```

### IPTables Rules

```bash
#!/bin/bash
# iptables-rules.sh

# Flush existing rules
iptables -F
iptables -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow Prometheus from specific subnet
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 9090 -j ACCEPT

# Allow Grafana from specific subnet
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 3000 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

## Reverse Proxy with Nginx

### Nginx Configuration

Create `/etc/nginx/sites-available/monitoring`:

```nginx
# Grafana
upstream grafana {
    server 127.0.0.1:3000;
}

# Prometheus
upstream prometheus {
    server 127.0.0.1:9090;
}

# Grafana HTTPS server
server {
    listen 443 ssl http2;
    server_name grafana.example.com;

    ssl_certificate /etc/letsencrypt/live/grafana.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/grafana.example.com/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=grafana_limit:10m rate=10r/s;
    limit_req zone=grafana_limit burst=20 nodelay;
    
    # Client authentication (optional)
    # auth_basic "Restricted Access";
    # auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://grafana;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Grafana Live WebSocket
    location /api/live/ {
        proxy_pass http://grafana;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}

# Prometheus HTTPS server
server {
    listen 443 ssl http2;
    server_name prometheus.example.com;

    ssl_certificate /etc/letsencrypt/live/prometheus.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/prometheus.example.com/privkey.pem;
    
    # SSL configuration (same as above)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    
    # IP whitelist for Prometheus
    allow 192.168.1.0/24;
    deny all;
    
    # Basic authentication
    auth_basic "Prometheus Access";
    auth_basic_user_file /etc/nginx/.htpasswd-prometheus;
    
    location / {
        proxy_pass http://prometheus;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name grafana.example.com prometheus.example.com;
    return 301 https://$server_name$request_uri;
}
```

Create htpasswd file:

```bash
# Install apache2-utils
sudo apt-get install apache2-utils

# Create htpasswd file for Prometheus
sudo htpasswd -c /etc/nginx/.htpasswd-prometheus admin
sudo htpasswd /etc/nginx/.htpasswd-prometheus user2

# Set proper permissions
sudo chmod 640 /etc/nginx/.htpasswd-prometheus
sudo chown www-data:www-data /etc/nginx/.htpasswd-prometheus
```

Enable site and reload nginx:

```bash
sudo ln -s /etc/nginx/sites-available/monitoring /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Security Hardening

### Disable Unnecessary Features

```ini
# grafana.ini
[snapshots]
external_enabled = false

[dashboards]
versions_to_keep = 20

[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer

[auth.anonymous]
enabled = false

[auth.basic]
enabled = true

[auth.proxy]
enabled = false
```

### Rate Limiting

```yaml
# Prometheus command line flags
command:
  - '--web.config.file=/etc/prometheus/web-config.yml'
  - '--query.max-concurrency=20'
  - '--query.max-samples=50000000'
```

### Audit Logging

```ini
# grafana.ini
[log]
mode = console file
level = info

[auditing]
enabled = true
loggers = console file
log_dashboard_content = true
```

## Security Best Practices Checklist

- ✅ **TLS/SSL**: Enable TLS for all communications
- ✅ **Strong Passwords**: Use strong, unique passwords (20+ characters)
- ✅ **Secrets Management**: Never hardcode credentials
- ✅ **Authentication**: Enable authentication on all services
- ✅ **Authorization**: Use RBAC with principle of least privilege
- ✅ **Network Segmentation**: Isolate monitoring network
- ✅ **Firewall Rules**: Whitelist only required IPs
- ✅ **Regular Updates**: Keep all components up to date
- ✅ **Audit Logging**: Enable comprehensive logging
- ✅ **Rate Limiting**: Prevent abuse and DoS attacks
- ✅ **Security Headers**: Set proper HTTP security headers
- ✅ **Backup Encryption**: Encrypt backups at rest
- ✅ **Penetration Testing**: Regularly test security posture
- ✅ **Incident Response**: Have incident response plan

## Security Monitoring

Monitor your monitoring stack for security issues:

```yaml
# prometheus-security-alerts.yml
groups:
  - name: security_alerts
    interval: 1m
    rules:
      - alert: TooManyFailedLogins
        expr: rate(grafana_api_failure_total[5m]) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Too many failed login attempts"
          
      - alert: TLSCertificateExpiringSoon
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "TLS certificate expiring in {{ $value }} days"
```

## References

- [Prometheus Security Best Practices](https://prometheus.io/docs/operating/security/)
- [Grafana Security Documentation](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/)
- [OWASP Security Guidelines](https://owasp.org/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

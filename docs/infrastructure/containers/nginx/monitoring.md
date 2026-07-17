---
title: Nginx Monitoring and Troubleshooting
description: Monitoring Nginx with the status module, useful operational commands, and solutions to common issues
author: josephstreeter
ms.author: josephstreeter
ms.date: 2026-07-17
ms.topic: how-to
ms.service: infrastructure
---

## Monitoring and Troubleshooting

### Enable Status Module

```nginx
server {
    listen 8080;
    server_name localhost;
    
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
    
    location /upstream_status {
        # nginx plus feature
        # status;
        access_log off;
    }
}
```

### Useful Commands

```bash
# Test nginx configuration
docker exec nginx-proxy nginx -t

# Reload nginx configuration
docker exec nginx-proxy nginx -s reload

# View nginx status
curl http://localhost:8080/nginx_status

# Monitor access logs
docker exec nginx-proxy tail -f /var/log/nginx/access.log

# Check upstream server status
docker exec nginx-proxy cat /var/log/nginx/error.log | grep upstream

# Test configuration syntax
docker run --rm -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf nginx nginx -t
```

### Common Issues and Solutions

1. **502 Bad Gateway**

   ```bash
   # Check if backend servers are running
   docker-compose ps
   
   # Check network connectivity
   docker exec nginx-proxy ping my-apache-app1
   ```

2. **504 Gateway Timeout**

   ```nginx
   # Increase timeout values
   proxy_connect_timeout 60s;
   proxy_send_timeout 60s;
   proxy_read_timeout 60s;
   ```

3. **Connection refused**

   ```bash
   # Verify backend server ports
   docker exec my-apache-app1 netstat -tlnp
   ```

## Navigation

[◄ TLS / Let's Encrypt](tls.md) · [Nginx Overview](index.md) · [Best Practices ►](best-practices.md)

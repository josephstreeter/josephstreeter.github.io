# Grafana

This page will cover using Grafana and Prometheus to monitor a home network.

## Prometheus

Prometheus is....

### Node Exporter

Install Node Exporter on Linux. The Node Exporter will export system related stats.

- Create a Node Exporter user, required directories, and make prometheus user as the owner of those directories.

```bash
sudo groupadd -f node_exporter
sudo useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
sudo mkdir /etc/node_exporter
sudo chown node_exporter:node_exporter /etc/node_exporter
```

- Download the Node Exporter binary to the server you want to monitor.

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.0/node_exporter-1.9.0.linux-amd64.tar.gz

```

- Extract and move the Node Exporter binary

```bash
tar -zxvf node_exporter-1.9.0.linux-amd64.tar.gz
mv node_exporter-1.9.0.linux-amd64 node_exporter
```

- Install Node Exporter by Coping the ```node_exporter``` binary from ```node_exporter-files``` folder to ```/usr/bin``` and change the ownership to the prometheus user.

```bash
sudo cp node_exporter/node_exporter /usr/bin/
sudo chown node_exporter:node_exporter /usr/bin/node_exporter
```

- Setup Node Exporter Service by creating a node_exporter service file.

```bash
sudo vi /usr/lib/systemd/system/node_exporter.service
```

- Add the following configuration information to the node_exporter service file.

```text
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter \
  --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
```

Set permissions on the node_exporter service file.

```bash
sudo chmod 664 /usr/lib/systemd/system/node_exporter.service
```

- Reload the systemd service to register and start the node_exporter service.

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
```

- Configure node_exporter to start at boot

```bash
sudo systemctl enable node_exporter.service
```

- Check the node exporter service status.

```bash
sudo systemctl status node_exporter
```

- Verify that the node_exporter service is exporting metrics.

```text
http://<server-ip>:9100/metrics
```

- Clean up by Removing the downloaded and temporary files.

```bash
rm -rf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-files
```

Complete script to install and configure Node Exporter

```bash
#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or with sudo" 1>&2
   exit 1
fi

echo "Create directory, user and group for node_exporter"
groupadd -f node_exporter
useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
mkdir /etc/node_exporter
chown node_exporter:node_exporter /etc/node_exporter

echo "Download node_exporter to /tmp"
pushd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.0/node_exporter-1.9.0.linux-amd64.tar.gz
popd

echo "Extract and rename node_exporter folder"
tar -zxvf node_exporter-1.9.0.linux-amd64.tar.gz
mv node_exporter-1.9.0.linux-amd64 node_exporter

echo "Copy binary to /usr/bin and set owner"
cp node_exporter/node_exporter /usr/bin/
chown node_exporter:node_exporter /usr/bin/node_exporter

echo "Create systemd service file"
cat << EOF >> /usr/lib/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

echo "Set owner of node_exporter service file"
chmod 664 /usr/lib/systemd/system/node_exporter.service

echo "Restart and enable node_exporter"
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter.service

echo "finished!"
```

## Add Node Exporter to Prometheus

Add the following to the Prometheus configuration file.

```yaml
- job_name: '<job name>'
    scrape_interval:     15s
    scrape_timeout:      10s
    static_configs:
      - targets: ['<hostname or IP>:9100']
```

Restart Prometheus to use the new config.

### Container Advisor (cAdvisor)

cAdvisor (short for Container Advisor) analyzes and exposes resource usage and performance data from running containers. cAdvisor exposes Prometheus metrics out of the box. 

Docker Compose

Add the following information to your Docker Compose file under "services."

```yaml
cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
    - 8080:8080
    volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:rw
    - /sys:/sys:ro
    - /var/lib/docker/:/var/lib/docker:ro
```

Checking Metrics

Once all the services are up we can open the Dashboard. 

```text
http://localhost:8080
```

Take a look at the metrics being produced in Prometheus metrics format

```text
http://localhost:8080/metrics
```

Configure Prometheus

Configure Prometheus to scrape metrics from cAdvisor. Add the following to the prometheus.yml configuration file.

```yaml
scrape_configs:
- job_name: cadvisor
  scrape_interval: 5s
  static_configs:
  - targets:
    - cadvisor:8080
```

### Unpoller

Create an account named ```unifipoller``` on the UDP Pro that has read-only access to the network.

```yaml
unpoller:
    image: ghcr.io/unpoller/unpoller:latest
    restart: unless-stopped
    ports:
      - '9130:9130'
    container_name: unpoller
    environment:
      - UP_INFLUXDB_DISABLE=true
      - UP_POLLER_DEBUG=false
      - UP_UNIFI_DYNAMIC=false
      - UP_PROMETHEUS_HTTP_LISTEN=0.0.0.0:9130
      - UP_PROMETHEUS_NAMESPACE=unpoller
      - UP_UNIFI_CONTROLLER_0_PASS=unpoller12345
      - UP_UNIFI_CONTROLLER_0_SAVE_ALARMS=true
      - UP_UNIFI_CONTROLLER_0_SAVE_ANOMALIES=true
      - UP_UNIFI_CONTROLLER_0_SAVE_DPI=true
      - UP_UNIFI_CONTROLLER_0_SAVE_EVENTS=true
      - UP_UNIFI_CONTROLLER_0_SAVE_IDS=true
      - UP_UNIFI_CONTROLLER_0_SAVE_SITES=true
      - UP_UNIFI_CONTROLLER_0_URL=https://192.168.14.250
      - UP_UNIFI_CONTROLLER_0_USER=unpoller
```

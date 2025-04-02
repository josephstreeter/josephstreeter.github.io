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

groupadd -f node_exporter
useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
mkdir /etc/node_exporter
chown node_exporter:node_exporter /etc/node_exporter

wget https://github.com/prometheus/node_exporter/releases/download/v1.9.0/node_exporter-1.9.0.linux-amd64.tar.gz

tar -zxvf node_exporter-1.9.0.linux-amd64.tar.gz
mv node_exporter-1.9.0.linux-amd64 node_exporter

cp node_exporter/node_exporter /usr/bin/
chown node_exporter:node_exporter /usr/bin/node_exporter

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

chmod 664 /usr/lib/systemd/system/node_exporter.service
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter.service
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

http://localhost:8080

Take a look at the metrics being produced in Prometheus metrics format

http://localhost:8080/metrics

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
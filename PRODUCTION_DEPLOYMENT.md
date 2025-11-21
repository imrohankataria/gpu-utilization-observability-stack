# Production Deployment Guide

This guide covers deploying the GPU Observability Stack in production environments.

## Prerequisites

### Hardware Requirements
- NVIDIA GPU(s) - Any CUDA-compatible GPU
- Minimum 4GB RAM for the monitoring stack
- 20GB disk space for metrics storage (30 days retention)
- Network connectivity between monitoring stack and GPU nodes

### Software Requirements
- Docker Engine 20.10+
- Docker Compose v2.0+
- NVIDIA Container Toolkit
- Linux host (Ubuntu 20.04+, RHEL/CentOS 8+, or similar)

## Installation Steps

### 1. Install NVIDIA Container Toolkit

**Ubuntu/Debian:**
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

**RHEL/CentOS:**
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | \
  sudo tee /etc/yum.repos.d/nvidia-docker.repo
sudo yum install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 2. Verify GPU Access

```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
```

### 3. Clone and Configure

```bash
git clone https://github.com/imrohankataria/gpu-utilization-observability-stack.git
cd gpu-utilization-observability-stack

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

### 4. Customize for Production

#### Update Grafana Credentials
Edit `docker-compose.yml`:
```yaml
environment:
  - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-changeme123!}
```

#### Configure Persistent Storage
Ensure data directories have proper permissions:
```bash
sudo mkdir -p /var/lib/gpu-monitoring/{prometheus,grafana,alertmanager}
sudo chown -R 65534:65534 /var/lib/gpu-monitoring/prometheus
sudo chown -R 472:472 /var/lib/gpu-monitoring/grafana
sudo chown -R 65534:65534 /var/lib/gpu-monitoring/alertmanager
```

Update `docker-compose.yml` volumes:
```yaml
volumes:
  prometheus_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /var/lib/gpu-monitoring/prometheus
  grafana_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /var/lib/gpu-monitoring/grafana
```

#### Configure Alert Notifications
Edit `alertmanager/alertmanager.yml` with your Slack, PagerDuty, or email settings.

See `examples/ALERT_EXAMPLES.md` for configuration examples.

### 5. Deploy the Stack

```bash
# Start services
./start.sh

# Or manually
docker compose up -d

# Check status
docker compose ps
./health-check.sh
```

## Security Hardening

### 1. Enable Authentication

#### Grafana
Grafana has built-in authentication. Additional options:

**LDAP Integration:**
Add to `docker-compose.yml`:
```yaml
volumes:
  - ./grafana/ldap.toml:/etc/grafana/ldap.toml:ro
environment:
  - GF_AUTH_LDAP_ENABLED=true
  - GF_AUTH_LDAP_CONFIG_FILE=/etc/grafana/ldap.toml
```

**OAuth2:**
```yaml
environment:
  - GF_AUTH_GENERIC_OAUTH_ENABLED=true
  - GF_AUTH_GENERIC_OAUTH_CLIENT_ID=your_client_id
  - GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=your_client_secret
  - GF_AUTH_GENERIC_OAUTH_AUTH_URL=https://your-oauth-provider/auth
  - GF_AUTH_GENERIC_OAUTH_TOKEN_URL=https://your-oauth-provider/token
```

#### Prometheus
Add basic auth with reverse proxy (nginx example):

```nginx
location /prometheus/ {
    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://localhost:9090/;
}
```

### 2. Network Isolation

Create a dedicated Docker network:
```yaml
networks:
  gpu-monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

### 3. TLS/SSL Configuration

Use a reverse proxy (nginx, traefik) with SSL certificates:

**Traefik Example:**
```yaml
services:
  traefik:
    image: traefik:v2.10
    command:
      - --providers.docker=true
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.myresolver.acme.tlschallenge=true
      - --certificatesresolvers.myresolver.acme.email=admin@example.com
    ports:
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/acme.json:/acme.json
    networks:
      - gpu-monitoring

  grafana:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.yourdomain.com`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=myresolver"
```

### 4. Firewall Rules

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 443/tcp   # HTTPS (if using reverse proxy)
sudo ufw deny 3000/tcp   # Block direct Grafana access
sudo ufw deny 9090/tcp   # Block direct Prometheus access
sudo ufw enable
```

## High Availability Setup

### Multi-Node Prometheus

Use Prometheus federation:

**Central Prometheus:**
```yaml
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"dcgm.*"}'
    static_configs:
      - targets:
        - 'prometheus-node1:9090'
        - 'prometheus-node2:9090'
```

### Grafana HA

Use external database:
```yaml
environment:
  - GF_DATABASE_TYPE=postgres
  - GF_DATABASE_HOST=postgres:5432
  - GF_DATABASE_NAME=grafana
  - GF_DATABASE_USER=grafana
  - GF_DATABASE_PASSWORD=secret
```

Deploy multiple Grafana instances behind a load balancer.

## Backup and Recovery

### Backup Prometheus Data

```bash
# Create backup
docker compose exec prometheus tar czf /prometheus/backup-$(date +%Y%m%d).tar.gz -C /prometheus .

# Copy to backup location
docker cp prometheus:/prometheus/backup-*.tar.gz /backup/prometheus/
```

### Backup Grafana Dashboards

```bash
# Export dashboards
docker compose exec grafana grafana-cli admin export-dashboards /var/lib/grafana/dashboards

# Backup Grafana database
docker compose exec grafana sqlite3 /var/lib/grafana/grafana.db ".backup '/var/lib/grafana/backup.db'"
```

### Restore from Backup

```bash
# Stop services
docker compose down

# Restore Prometheus data
tar xzf backup.tar.gz -C /var/lib/gpu-monitoring/prometheus/

# Restore Grafana
cp backup.db /var/lib/gpu-monitoring/grafana/grafana.db

# Start services
docker compose up -d
```

## Monitoring the Monitoring Stack

### Resource Monitoring

Add node-exporter to monitor host resources:
```yaml
services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - 9100:9100
    networks:
      - gpu-monitoring
```

Add to Prometheus scrape config:
```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Health Checks

Set up automated health checks:
```bash
# Add to crontab
*/5 * * * * /path/to/health-check.sh >> /var/log/gpu-monitoring-health.log 2>&1
```

## Scaling Considerations

### For 100+ GPUs

1. **Increase Prometheus resources:**
```yaml
services:
  prometheus:
    deploy:
      resources:
        limits:
          memory: 8G
        reservations:
          memory: 4G
```

2. **Use remote storage:**
```yaml
remote_write:
  - url: "https://your-remote-storage/api/v1/write"
    basic_auth:
      username: "user"
      password: "pass"
```

3. **Adjust retention:**
```yaml
command:
  - '--storage.tsdb.retention.time=15d'  # Reduce from 30d
```

### For Multiple Clusters

Use Grafana's data source provisioning for multiple Prometheus instances:
```yaml
# grafana/provisioning/datasources/multi-cluster.yml
apiVersion: 1
datasources:
  - name: Cluster-A
    type: prometheus
    url: http://prometheus-cluster-a:9090
  - name: Cluster-B
    type: prometheus
    url: http://prometheus-cluster-b:9090
```

## Maintenance

### Regular Tasks

**Daily:**
- Check alert status
- Review cost dashboards
- Monitor disk usage

**Weekly:**
- Review and optimize underutilized GPUs
- Update alert thresholds based on usage patterns
- Check for software updates

**Monthly:**
- Rotate logs
- Review and clean up old metrics
- Update documentation
- Test backup restoration

### Updates

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Check logs
docker compose logs -f
```

## Troubleshooting Production Issues

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

### Performance Issues

If Prometheus is slow:
```bash
# Check disk I/O
iostat -x 1

# Check memory usage
docker stats prometheus

# Optimize queries
# Use recording rules for expensive queries
```

### High Memory Usage

```bash
# Reduce retention
# Edit docker-compose.yml
--storage.tsdb.retention.time=15d

# Restart
docker compose restart prometheus
```

## Support

For production support:
- Open an issue on GitHub
- Consult NVIDIA DCGM documentation
- Join Prometheus/Grafana community forums

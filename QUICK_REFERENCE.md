# Quick Reference Card

## Essential Commands

### Start/Stop Stack
```bash
./start.sh                    # Start all services
./stop.sh                     # Stop all services
docker compose restart        # Restart all services
docker compose down -v        # Stop and remove volumes (DELETES DATA!)
```

### Check Status
```bash
./health-check.sh             # Comprehensive health check
docker compose ps             # Service status
docker compose logs -f        # Follow all logs
docker compose logs -f dcgm-exporter  # Specific service logs
```

### Access Dashboards
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **DCGM Metrics**: http://localhost:9400/metrics

## Common Operations

### View GPU Metrics
```bash
# Check if DCGM is collecting metrics
curl http://localhost:9400/metrics | grep DCGM_FI_DEV_GPU_UTIL

# Count GPUs detected
curl -s http://localhost:9400/metrics | grep -c "DCGM_FI_DEV_GPU_UTIL{"

# View current GPU utilization
nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader
```

### Query Prometheus
```bash
# Average GPU utilization
curl 'http://localhost:9090/api/v1/query?query=avg(DCGM_FI_DEV_GPU_UTIL)'

# Idle GPU percentage
curl 'http://localhost:9090/api/v1/query?query=avg(100-DCGM_FI_DEV_GPU_UTIL)'

# Current alerts
curl 'http://localhost:9090/api/v1/alerts'
```

### Grafana Operations
```bash
# Reset admin password
docker compose exec grafana grafana-cli admin reset-admin-password newpassword

# List dashboards
docker compose exec grafana grafana-cli admin list-dashboards

# Create API key
curl -X POST -H "Content-Type: application/json" -d '{"name":"apikey", "role": "Viewer"}' \
  http://admin:admin@localhost:3000/api/auth/keys
```

## Troubleshooting Quick Fixes

### DCGM Exporter Issues
```bash
# Check GPU access
docker exec dcgm-exporter nvidia-smi

# Restart DCGM
docker compose restart dcgm-exporter

# View detailed logs
docker compose logs dcgm-exporter --tail=100
```

### Prometheus Issues
```bash
# Check targets status
curl http://localhost:9090/api/v1/targets | jq

# Reload configuration
curl -X POST http://localhost:9090/-/reload

# Check alert rules
curl http://localhost:9090/api/v1/rules | jq
```

### Grafana Issues
```bash
# Test datasource connection
curl http://localhost:3000/api/datasources/1/health \
  -u admin:admin

# Reload dashboards
docker compose restart grafana

# Check Grafana logs
docker compose logs grafana --tail=50
```

## Configuration Changes

### Update Alert Thresholds
```bash
# Edit alert rules
nano prometheus/alerts.yml

# Reload Prometheus
curl -X POST http://localhost:9090/-/reload

# Verify rules loaded
curl http://localhost:9090/api/v1/rules
```

### Change GPU Cost Pricing
```bash
# Edit dashboards in Grafana UI
# Or edit JSON files directly
nano grafana/dashboards/gpu-cost-analysis.json

# Restart Grafana to reload
docker compose restart grafana
```

### Configure Alert Notifications
```bash
# Edit AlertManager config
nano alertmanager/alertmanager.yml

# Restart AlertManager
docker compose restart alertmanager

# Test alert routing
curl -H "Content-Type: application/json" -d '[{
  "labels": {"alertname":"test","severity":"warning"},
  "annotations": {"summary":"Test alert"}
}]' http://localhost:9093/api/v1/alerts
```

## Backup & Recovery

### Quick Backup
```bash
# Backup all data
tar czf gpu-monitoring-backup-$(date +%Y%m%d).tar.gz \
  prometheus_data/ grafana_data/ alertmanager_data/

# Backup configuration only
tar czf gpu-monitoring-config-$(date +%Y%m%d).tar.gz \
  prometheus/ grafana/ alertmanager/ docker-compose.yml
```

### Quick Restore
```bash
# Stop services
docker compose down

# Restore data
tar xzf gpu-monitoring-backup-*.tar.gz

# Start services
docker compose up -d
```

## Performance Optimization

### Reduce Memory Usage
```bash
# Edit retention in docker-compose.yml
# Change: --storage.tsdb.retention.time=30d
# To: --storage.tsdb.retention.time=15d

docker compose up -d --force-recreate prometheus
```

### Increase Scrape Interval
```bash
# Edit prometheus/prometheus.yml
# Change: scrape_interval: 15s
# To: scrape_interval: 30s

curl -X POST http://localhost:9090/-/reload
```

## Useful Prometheus Queries

```promql
# GPU Utilization
avg(DCGM_FI_DEV_GPU_UTIL)
DCGM_FI_DEV_GPU_UTIL{gpu="0"}

# Idle %
100 - DCGM_FI_DEV_GPU_UTIL

# Memory Usage %
(DCGM_FI_DEV_FB_USED / (DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE)) * 100

# Cost (assuming $2/hour)
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2)

# Active GPUs
count(DCGM_FI_DEV_GPU_UTIL > 20)

# GPU Count
count(DCGM_FI_DEV_GPU_UTIL)
```

## Alert Management

### Silence Alerts
```bash
# Silence alert for 2 hours
curl -X POST -H "Content-Type: application/json" -d '{
  "matchers": [{"name":"alertname","value":"HighGPUIdle"}],
  "startsAt": "2024-01-01T00:00:00Z",
  "endsAt": "2024-01-01T02:00:00Z",
  "comment": "Planned maintenance"
}' http://localhost:9093/api/v1/silences

# List active silences
curl http://localhost:9093/api/v1/silences | jq
```

### View Active Alerts
```bash
# All active alerts
curl http://localhost:9093/api/v1/alerts | jq

# Firing alerts only
curl http://localhost:9093/api/v1/alerts | jq '.data[] | select(.status.state=="active")'
```

## Docker Management

### Clean Up Resources
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Full cleanup (careful!)
docker system prune -a --volumes
```

### View Resource Usage
```bash
# Container stats
docker stats

# Disk usage
docker system df

# Detailed volume usage
docker system df -v
```

## Emergency Procedures

### Complete Reset
```bash
# WARNING: This deletes all data!
docker compose down -v
rm -rf prometheus_data grafana_data alertmanager_data
./start.sh
```

### Service Recovery
```bash
# If a service keeps failing
docker compose stop <service>
docker compose rm -f <service>
docker compose up -d <service>
```

### Data Corruption Recovery
```bash
# If Prometheus data is corrupted
docker compose stop prometheus
rm -rf prometheus_data/*
docker compose start prometheus
# Note: All historical data will be lost
```

## Monitoring Checklists

### Daily Health Check
- [ ] Check ./health-check.sh output
- [ ] Verify all services are running
- [ ] Review active alerts
- [ ] Check disk space usage

### Weekly Review
- [ ] Analyze cost dashboard
- [ ] Review idle GPU trends
- [ ] Update alert thresholds if needed
- [ ] Check for software updates

### Monthly Maintenance
- [ ] Backup all data
- [ ] Review and optimize queries
- [ ] Clean up old metrics if needed
- [ ] Update documentation

## Getting Help

- 📖 Full documentation: [README.md](README.md)
- 🔧 Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 🚀 Production setup: [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
- 💡 Alert examples: [examples/ALERT_EXAMPLES.md](examples/ALERT_EXAMPLES.md)
- 📊 Query examples: [examples/PROMETHEUS_QUERIES.md](examples/PROMETHEUS_QUERIES.md)
- 🐛 Report issues: https://github.com/imrohankataria/gpu-utilization-observability-stack/issues

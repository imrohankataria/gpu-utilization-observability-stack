# Troubleshooting Guide

## Common Issues and Solutions

### Issue: DCGM Exporter fails to start

**Symptoms:**
- Container exits immediately
- Error: "Failed to initialize DCGM"

**Solutions:**

1. **Check NVIDIA Container Toolkit installation:**
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
```

2. **Verify GPU access:**
```bash
nvidia-smi
```

3. **Check Docker runtime configuration:**
```bash
cat /etc/docker/daemon.json
# Should contain:
# {
#   "runtimes": {
#     "nvidia": {
#       "path": "nvidia-container-runtime",
#       "runtimeArgs": []
#     }
#   }
# }
```

4. **Restart Docker daemon:**
```bash
sudo systemctl restart docker
```

### Issue: No metrics in Grafana

**Symptoms:**
- Dashboards show "No data"
- Empty graphs

**Solutions:**

1. **Check Prometheus is scraping DCGM:**
```bash
curl http://localhost:9090/api/v1/targets
# Look for dcgm-exporter target with state="up"
```

2. **Verify DCGM metrics endpoint:**
```bash
curl http://localhost:9400/metrics | grep DCGM_FI_DEV_GPU_UTIL
```

3. **Check Prometheus logs:**
```bash
docker-compose logs prometheus
```

4. **Verify Grafana datasource:**
- Go to Configuration → Data Sources
- Test the Prometheus connection
- Should show "Data source is working"

### Issue: Alerts not firing

**Symptoms:**
- Expected alerts don't appear
- AlertManager shows no alerts

**Solutions:**

1. **Check alert rules are loaded:**
```bash
curl http://localhost:9090/api/v1/rules
```

2. **Verify alert conditions:**
```bash
# Query Prometheus directly
curl 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_UTIL'
```

3. **Check AlertManager configuration:**
```bash
docker-compose logs alertmanager
```

4. **Test alert rule syntax:**
```bash
docker exec prometheus promtool check rules /etc/prometheus/alerts.yml
```

### Issue: High memory usage

**Symptoms:**
- Prometheus container using excessive memory
- System slowdown

**Solutions:**

1. **Reduce retention time:**
Edit `docker-compose.yml`:
```yaml
--storage.tsdb.retention.time=15d  # Reduce from 30d
```

2. **Increase scrape interval:**
Edit `prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 30s  # Increase from 15s
```

3. **Limit metric cardinality:**
- Reduce number of labels
- Use recording rules for expensive queries

### Issue: Container over-allocation alert firing incorrectly

**Symptoms:**
- Alert fires but you have ≤8 GPUs per instance

**Solutions:**

1. **Check actual GPU count:**
```bash
nvidia-smi --list-gpus | wc -l
```

2. **Verify DCGM is reporting correctly:**
```bash
docker exec dcgm-exporter dcgmi discovery -l
```

3. **Adjust alert threshold:**
Edit `prometheus/alerts.yml`:
```yaml
expr: count(DCGM_FI_DEV_GPU_UTIL) by (instance) > 16  # Adjust threshold
```

### Issue: Permission denied errors

**Symptoms:**
- Cannot write to data directories
- "Permission denied" in logs

**Solutions:**

1. **Fix directory permissions:**
```bash
sudo chown -R 65534:65534 prometheus_data
sudo chown -R 472:472 grafana_data
```

2. **Run with proper user:**
Add to `docker-compose.yml`:
```yaml
user: "65534:65534"  # For Prometheus
user: "472:472"      # For Grafana
```

### Issue: Grafana dashboards not loading

**Symptoms:**
- Dashboards menu is empty
- Provisioned dashboards don't appear

**Solutions:**

1. **Check provisioning directory permissions:**
```bash
ls -la grafana/provisioning/dashboards/
```

2. **Verify dashboard JSON files:**
```bash
ls -la grafana/dashboards/
```

3. **Check Grafana logs:**
```bash
docker-compose logs grafana | grep -i dashboard
```

4. **Re-provision dashboards:**
```bash
docker-compose restart grafana
```

### Issue: Network connectivity problems

**Symptoms:**
- Services cannot reach each other
- "Connection refused" errors

**Solutions:**

1. **Check Docker network:**
```bash
docker network ls
docker network inspect gpu-utilization-observability-stack_gpu-monitoring
```

2. **Verify service names resolve:**
```bash
docker exec prometheus ping -c 1 dcgm-exporter
docker exec grafana ping -c 1 prometheus
```

3. **Restart Docker network:**
```bash
docker-compose down
docker-compose up -d
```

## Debugging Commands

### View real-time logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dcgm-exporter
docker-compose logs -f prometheus
docker-compose logs -f grafana
```

### Restart services
```bash
# All services
docker-compose restart

# Specific service
docker-compose restart dcgm-exporter
```

### Check container status
```bash
docker-compose ps
docker stats
```

### Access container shell
```bash
docker exec -it dcgm-exporter /bin/bash
docker exec -it prometheus /bin/sh
docker exec -it grafana /bin/bash
```

### Test metrics collection
```bash
# Check DCGM exporter metrics
curl http://localhost:9400/metrics

# Query Prometheus
curl 'http://localhost:9090/api/v1/query?query=up'

# Check Grafana API
curl http://localhost:3000/api/health
```

## Getting Help

If you're still experiencing issues:

1. **Collect diagnostic information:**
```bash
./health-check.sh > diagnostics.txt
docker-compose logs >> diagnostics.txt
```

2. **Check GitHub Issues:**
   - Search existing issues
   - Open a new issue with diagnostics

3. **Community Support:**
   - NVIDIA DCGM: https://github.com/NVIDIA/dcgm-exporter
   - Prometheus: https://prometheus.io/community/
   - Grafana: https://community.grafana.com/

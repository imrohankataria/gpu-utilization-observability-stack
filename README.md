# GPU Utilization Observability Stack

> **Stop wasting up to 40% of your GPU hours.** Deploy a complete GPU observability stack to track idle time, VRAM misuse, container over-allocation, and calculate real $$ wasted.

## 🎯 Overview

Enterprises are burning money on underutilized GPUs. This project provides a production-ready observability stack that helps you:

- **Track GPU Idle %**: Identify GPUs sitting idle and wasting resources
- **Monitor VRAM Misuse**: Detect allocated but underutilized GPU memory
- **Detect Container Over-Allocation**: Find improperly configured GPU allocations
- **Calculate Real $$ Waste**: See exactly how much money you're wasting on idle GPUs
- **Visualize GPU Burn**: Heat maps and timelines showing utilization patterns

## 🏗️ Architecture

```
NVIDIA GPU → DCGM Exporter → Prometheus → Grafana
                                ↓
                          AlertManager
```

**Components:**
- **DCGM Exporter**: Collects GPU metrics directly from NVIDIA GPUs using NVIDIA's DCGM
- **Prometheus**: Time-series database for metrics storage and querying
- **Grafana**: Visualization platform with pre-built dashboards
- **AlertManager**: Routes alerts to appropriate teams (Slack, PagerDuty, email, etc.)

## 📊 Pre-Built Dashboards

### 1. GPU Utilization Dashboard
- Real-time GPU utilization gauges
- GPU idle % tracking
- VRAM usage and allocation
- Power consumption monitoring
- Temperature tracking

### 2. GPU Cost Analysis Dashboard
- **Estimated wasted $$ per hour** (configurable pricing)
- Total idle GPU hours
- Waste percentage calculations
- Cost trends over time
- Projected monthly waste
- Potential savings analysis

### 3. GPU Utilization Heatmap
- Visual burn map showing GPU activity patterns
- GPU status matrix
- Activity timeline (idle vs active)
- Time spent in each utilization band

### 4. GPU Container Allocation Dashboard
- GPU distribution across instances
- Memory allocation efficiency
- Over-allocation detection (>8 GPUs per instance)
- Resource utilization efficiency metrics

## 🚨 Alert Rules

Pre-configured alerts for:
- **High GPU Idle**: GPUs idle >80% for >30 minutes
- **Low GPU Utilization**: Avg utilization <20% for >1 hour
- **VRAM Waste**: Memory allocated but <20% utilized
- **High VRAM Usage**: Memory >90% (OOM risk)
- **GPU Over-Allocation**: >8 GPUs per instance
- **High GPU Temperature**: Temperature >85°C
- **GPU XID Errors**: Hardware errors detected
- **Inefficient Power Usage**: High power consumption with low utilization
- **Multiple Idle GPUs**: >2 GPUs idle simultaneously

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- NVIDIA GPU(s)
- NVIDIA Container Toolkit installed
- Linux host (Ubuntu 20.04+ recommended)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/imrohankataria/gpu-utilization-observability-stack.git
cd gpu-utilization-observability-stack
```

2. **Verify NVIDIA Container Toolkit:**
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
```

3. **Start the stack:**
```bash
docker-compose up -d
```

4. **Access the dashboards:**
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

### First-Time Setup

1. **Log into Grafana** (http://localhost:3000)
   - Username: `admin`
   - Password: `admin` (you'll be prompted to change it)

2. **Navigate to Dashboards** → Browse
   - GPU Utilization Dashboard
   - GPU Cost Analysis Dashboard
   - GPU Utilization Heatmap
   - GPU Container Allocation

3. **Configure cost parameters** (optional):
   - Edit the Cost Analysis dashboard
   - Adjust the GPU hourly cost in the panel queries (default: $2/hour)
   - Update based on your cloud provider pricing (AWS p3.2xlarge ≈ $3/hr, GCP A100 ≈ $2.93/hr, etc.)

## ⚙️ Configuration

### Customize GPU Pricing

Edit the cost calculation in Grafana dashboards to match your pricing:

```promql
# Default: $2/hour per GPU
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2)

# For $3/hour:
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 3)
```

### Configure Alerts

Edit `prometheus/alerts.yml` to adjust alert thresholds:

```yaml
# Example: Change idle threshold from 80% to 70%
- alert: HighGPUIdle
  expr: (1 - (DCGM_FI_DEV_GPU_UTIL / 100)) * 100 > 70  # Changed from 80
  for: 30m
```

### Setup Alert Notifications

Edit `alertmanager/alertmanager.yml` to configure notifications:

**Slack Example:**
```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

receivers:
  - name: 'cost-optimization-team'
    slack_configs:
      - channel: '#gpu-cost-optimization'
        title: 'GPU Waste Alert'
```

**Email Example:**
```yaml
receivers:
  - name: 'ops-team'
    email_configs:
      - to: 'ops-team@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'alerts@example.com'
        auth_password: 'your-app-password'
```

**PagerDuty Example:**
```yaml
receivers:
  - name: 'ops-team'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_INTEGRATION_KEY'
        severity: 'critical'
```

### Adjust Scrape Intervals

Edit `prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s     # How often to scrape metrics
  evaluation_interval: 15s # How often to evaluate rules
```

## 📈 Understanding Your GPU Waste

### Key Metrics

**GPU Utilization (`DCGM_FI_DEV_GPU_UTIL`)**
- 0-20%: **Idle** (wasting money)
- 20-40%: **Low** (investigate workload)
- 40-60%: **Medium** (could be optimized)
- 60-80%: **Good** (acceptable)
- 80-100%: **Optimal** (fully utilized)

**Cost Impact**
- **40% waste** = If you spend $100k/year on GPUs, you're wasting $40k
- **Each idle GPU hour** = Direct cost of that GPU instance (e.g., $2-3/hour)

### Action Items

**If you see high idle %:**
1. Consolidate workloads onto fewer GPUs
2. Scale down unused instances
3. Implement auto-scaling policies
4. Review container resource requests

**If you see VRAM waste:**
1. Reduce container memory limits
2. Optimize model batch sizes
3. Use mixed-precision training (FP16/BF16)
4. Profile memory usage patterns

**If you see over-allocation:**
1. Review Kubernetes resource limits
2. Check container GPU device mappings
3. Audit deployment configurations

## 🔧 Troubleshooting

### DCGM Exporter not collecting metrics

```bash
# Check if DCGM exporter can access GPUs
docker logs dcgm-exporter

# Verify GPU access
docker exec dcgm-exporter nvidia-smi

# Check DCGM health
docker exec dcgm-exporter dcgmi discovery -l
```

### No data in Grafana

```bash
# Check if Prometheus is scraping DCGM
curl http://localhost:9090/api/v1/targets

# Verify metrics endpoint
curl http://localhost:9400/metrics

# Check Prometheus logs
docker logs prometheus
```

### Alerts not firing

```bash
# Check alert rules status
curl http://localhost:9090/api/v1/rules

# Check AlertManager status
curl http://localhost:9093/api/v1/status

# View AlertManager logs
docker logs alertmanager
```

## 📁 Project Structure

```
.
├── docker-compose.yml              # Main orchestration file
├── prometheus/
│   ├── prometheus.yml             # Prometheus configuration
│   └── alerts.yml                 # Alert rules
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/          # Auto-provision Prometheus datasource
│   │   └── dashboards/           # Dashboard auto-loading config
│   └── dashboards/               # Pre-built JSON dashboards
│       ├── gpu-utilization.json
│       ├── gpu-cost-analysis.json
│       ├── gpu-heatmap.json
│       └── gpu-container-allocation.json
└── alertmanager/
    └── alertmanager.yml          # Alert routing configuration
```

## 🔐 Security Considerations

1. **Change default credentials**: Update Grafana admin password immediately
2. **Network isolation**: Run on private network or use reverse proxy with authentication
3. **Secure AlertManager**: Configure authentication for alert webhook endpoints
4. **HTTPS**: Use TLS/SSL certificates for production deployments
5. **Access control**: Implement role-based access control (RBAC) in Grafana

## 📊 Performance & Scaling

- **Storage**: Prometheus retention set to 30 days (configurable in `docker-compose.yml`)
- **Memory**: Allocate ~2GB RAM per 100 GPUs monitored
- **Scrape interval**: 15s default (reduce for less frequent updates, increase for more real-time data)
- **Disk space**: ~1GB per week per 100 GPUs (depends on cardinality)

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Add new dashboard panels
- Improve alert rules
- Submit bug fixes
- Enhance documentation

## 📝 License

MIT License - feel free to use this in your organization.

## 🆘 Support

- **Issues**: Open an issue on GitHub
- **Questions**: Start a discussion in GitHub Discussions

## 🎓 Learn More

- [NVIDIA DCGM Documentation](https://docs.nvidia.com/datacenter/dcgm/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [GPU Optimization Best Practices](https://docs.nvidia.com/deeplearning/performance/)

---

**Built to help enterprises stop wasting GPU resources and save money. Start monitoring today!** 🚀
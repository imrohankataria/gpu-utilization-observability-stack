# Getting Started by Role

This guide helps different team members get started with the GPU Observability Stack based on their role.

## 🎯 For Executives / Finance Leaders

### What You Need to Know
This stack shows exactly how much money you're wasting on idle GPUs. Most enterprises waste **40% of GPU hours**, which can mean tens of thousands of dollars per month.

### Quick Start (5 minutes)
1. Ask your DevOps team to deploy the stack (they run `./start.sh`)
2. Open the Cost Analysis Dashboard: http://localhost:3000/d/gpu-cost-analysis
3. Look at these key metrics:
   - **Estimated Wasted $ (Current Hour Rate)** - Real-time waste
   - **Projected Monthly Waste** - What you'll waste this month if nothing changes
   - **Potential Monthly Savings** - What you could save with optimization

### Key Questions This Answers
- ✅ How much are we wasting on idle GPUs?
- ✅ What's our GPU ROI?
- ✅ Where can we cut costs immediately?
- ✅ Which teams/projects are most inefficient?

### Action Items
- Review cost dashboard weekly
- Set cost reduction targets (aim for <20% idle)
- Track savings after optimization
- Use data for GPU purchasing decisions

---

## 💼 For FinOps / Cloud Cost Teams

### What You Need to Know
This gives you granular visibility into GPU utilization and cost metrics. You can track trends, identify waste, and prove ROI on optimization efforts.

### Quick Start (10 minutes)
1. Deploy the stack: `./start.sh`
2. Access Grafana: http://localhost:3000 (admin/admin)
3. Review these dashboards:
   - **Cost Analysis** - Current waste and projections
   - **GPU Utilization** - Real usage patterns
   - **Heatmap** - Visual burn analysis

### Customization
**Set Your GPU Pricing:**
1. Go to Cost Analysis dashboard
2. Edit panel → Query
3. Change the multiplier in queries:
   ```promql
   # Default: $2/hour
   sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2)
   
   # For $3/hour (e.g., AWS p3.2xlarge):
   sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 3)
   ```

### Key Metrics to Track
- **Waste Percentage** - Target: <20%
- **Idle Hours** - Track week-over-week
- **Cost per Team/Project** - Who's most efficient?
- **Utilization Trends** - Improving or getting worse?

### Reports to Generate
- Weekly waste summary for leadership
- Monthly cost optimization report
- Quarterly GPU ROI analysis
- Per-project utilization reports

### Best Practices
1. Set baseline metrics in week 1
2. Implement optimization plan
3. Track improvements weekly
4. Share wins with stakeholders
5. Adjust GPU purchases based on real usage

---

## 🔧 For DevOps / Infrastructure Teams

### What You Need to Know
This stack monitors GPU health, utilization, and allocation across your entire fleet. You'll get alerts for issues before they cause problems.

### Quick Start (15 minutes)
1. **Prerequisites:**
   ```bash
   # Verify NVIDIA runtime
   docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
   ```

2. **Deploy:**
   ```bash
   git clone https://github.com/imrohankataria/gpu-utilization-observability-stack.git
   cd gpu-utilization-observability-stack
   ./start.sh
   ```

3. **Verify:**
   ```bash
   ./health-check.sh
   ```

### Configuration Tasks

**1. Set Up Alerts (Priority: High)**
Edit `alertmanager/alertmanager.yml`:
```yaml
receivers:
  - name: 'ops-team'
    slack_configs:
      - channel: '#gpu-ops'
        webhook_url: 'YOUR_SLACK_WEBHOOK'
```

**2. Adjust Thresholds**
Edit `prometheus/alerts.yml` for your environment:
- GPU idle threshold (default: 80%)
- Temperature threshold (default: 85°C)
- Over-allocation threshold (default: >8 GPUs)

**3. Configure Retention**
Edit `docker-compose.yml`:
```yaml
--storage.tsdb.retention.time=30d  # Adjust as needed
```

### Dashboards to Monitor
- **GPU Utilization** - Health and performance
- **Container Allocation** - Resource distribution
- **Heatmap** - Usage patterns over time

### Alert Rules You'll Receive
- High GPU temperature (>85°C) - Check cooling
- XID errors - Hardware failure imminent
- GPU over-allocation - Configuration issue
- Multiple idle GPUs - Scaling opportunity

### Operational Tasks
**Daily:**
- Check health-check.sh output
- Review active alerts
- Monitor disk space

**Weekly:**
- Review utilization trends
- Update alert thresholds
- Check for updates

**Monthly:**
- Backup data
- Review and optimize queries
- Update documentation

### Troubleshooting
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.

Quick fixes:
```bash
# Restart a service
docker compose restart dcgm-exporter

# View logs
docker compose logs -f prometheus

# Check metrics
curl http://localhost:9400/metrics | grep DCGM
```

---

## 🤖 For ML/AI Engineers

### What You Need to Know
See how efficiently your training jobs use GPUs. Optimize batch sizes, improve utilization, and reduce costs.

### Quick Start (10 minutes)
1. Get access to Grafana from your DevOps team
2. Open: http://localhost:3000
3. Navigate to **GPU Utilization Dashboard**

### Key Metrics for You
- **GPU Utilization %** - Is your training using the GPU?
- **VRAM Usage** - Are you optimally using memory?
- **GPU Temperature** - Is your job causing thermal issues?
- **Power Consumption** - Energy efficiency

### Optimization Guide

**Low GPU Utilization (<40%)?**
- Increase batch size
- Check for CPU bottlenecks
- Optimize data loading pipeline
- Use mixed precision training (FP16)

**Low VRAM Usage (<40%)?**
- Increase batch size
- Request smaller GPU instance
- Share GPU with other jobs

**High Temperature (>80°C)?**
- Reduce batch size temporarily
- Check if cooling is adequate
- Consider spreading load across more GPUs

### Best Practices
1. **Before training:** Check GPU availability in the dashboard
2. **During training:** Monitor utilization in real-time
3. **After training:** Review efficiency metrics
4. **Optimize:** Use insights to improve next run

### Example Queries
Check your job's GPU usage:
```promql
# Your GPU utilization
DCGM_FI_DEV_GPU_UTIL{gpu="0"}

# Your VRAM usage
DCGM_FI_DEV_FB_USED{gpu="0"}
```

### Cost Awareness
If your training job runs at 30% GPU utilization for 24 hours on a $3/hour GPU:
- Cost: $72
- Effective usage: $21.60
- **Waste: $50.40** 😱

With 80% utilization:
- Cost: $72
- Effective usage: $57.60
- Waste: $14.40 ✅

---

## 📊 For Data Scientists

### What You Need to Know
Understand GPU resource consumption of your models and experiments. Make data-driven decisions about GPU allocation.

### Quick Start (5 minutes)
1. Access Grafana: http://localhost:3000
2. Open **GPU Utilization** and **Cost Analysis** dashboards
3. Find your GPU (look for your instance/node name)

### Questions This Answers
- ✅ Is my model efficiently using the GPU?
- ✅ How much memory does my model need?
- ✅ Can I run multiple experiments in parallel?
- ✅ What's the cost of my experiment?

### Optimization Tips

**Experiment Design:**
- Check historical utilization before requesting GPUs
- Size your GPU request based on actual usage
- Consider time-sharing if utilization is low

**Model Development:**
- Monitor VRAM during model loading
- Test different batch sizes for efficiency
- Use the heatmap to find optimal training times

**Cost Optimization:**
- Run experiments during off-peak (if cheaper)
- Batch similar experiments together
- Release GPUs immediately when done

### Sharing Insights
Use dashboard screenshots in your reports:
1. Go to dashboard
2. Click share icon (top right)
3. Select "Snapshot" or "Image rendering"
4. Include in experiment reports

---

## 🎯 For Team Leads / Managers

### What You Need to Know
Track your team's GPU efficiency, set targets, and demonstrate improvements to leadership.

### Quick Start (10 minutes)
1. Get Grafana access from DevOps
2. Review all 4 dashboards:
   - GPU Utilization (how hard we're working)
   - Cost Analysis (what we're wasting)
   - Heatmap (when we're using resources)
   - Container Allocation (how resources are distributed)

### Setting Team Goals

**Week 1: Baseline**
- Document current idle %
- Identify worst offenders
- Understand usage patterns

**Week 2-4: Quick Wins**
- Shut down idle instances
- Consolidate workloads
- Implement auto-scaling

**Month 2+: Optimization**
- Target: <20% idle time
- Improve job scheduling
- Optimize training parameters

### Team Metrics to Track
- **Team Idle %** - Target: <20%
- **Cost per Team Member** - Track trends
- **Utilization by Project** - Identify inefficiencies
- **Month-over-month Improvement** - Show progress

### Reporting to Leadership
Create monthly reports showing:
1. **Current waste %** and cost
2. **Improvement trend** (chart)
3. **Specific optimizations made**
4. **Projected annual savings**

Example narrative:
> "In Q1, we reduced GPU idle time from 45% to 18%, saving $12K/month. This was achieved by implementing auto-scaling and optimizing batch sizes. Projected annual savings: $144K."

### Team Best Practices
1. Share dashboard access with team
2. Review metrics in weekly meetings
3. Celebrate efficiency improvements
4. Make GPU efficiency a KPI
5. Document optimizations

---

## 🔐 For Security Teams

### What You Need to Know
This stack uses industry-standard components (Prometheus, Grafana) and can be secured following enterprise security practices.

### Security Checklist

**Authentication:**
- [ ] Change default Grafana password
- [ ] Enable Grafana OAuth/LDAP
- [ ] Implement network isolation
- [ ] Use reverse proxy with SSL

**Network Security:**
- [ ] Restrict port access (firewall rules)
- [ ] Use private networks
- [ ] Implement TLS/SSL certificates
- [ ] Set up VPN access if needed

**Access Control:**
- [ ] Implement RBAC in Grafana
- [ ] Limit who can edit dashboards
- [ ] Separate read/write access
- [ ] Audit access logs

**Data Protection:**
- [ ] Encrypt data at rest
- [ ] Secure backup procedures
- [ ] Implement data retention policies
- [ ] Regular security updates

### See Also
- [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) - Security hardening section
- Docker security best practices
- Prometheus security documentation

---

## 📚 Additional Resources

### Documentation
- **README.md** - Overview and quick start
- **TROUBLESHOOTING.md** - Common issues
- **PRODUCTION_DEPLOYMENT.md** - Enterprise setup
- **QUICK_REFERENCE.md** - Command cheat sheet
- **FEATURES.md** - Complete feature list

### Examples
- **examples/ALERT_EXAMPLES.md** - Notification setup
- **examples/PROMETHEUS_QUERIES.md** - Query library

### Community
- GitHub Issues - Report problems
- GitHub Discussions - Ask questions
- NVIDIA DCGM Documentation
- Prometheus Community
- Grafana Community

---

## 🚀 Next Steps

1. **Deploy the stack** using the guide for your role above
2. **Review relevant dashboards** for your needs
3. **Set up alerts** if applicable to your role
4. **Take action** on insights discovered
5. **Share findings** with your team
6. **Track improvements** over time

**Remember:** The goal isn't just monitoring—it's taking action to optimize GPU usage and reduce waste!

---

**Need help?** Open an issue on GitHub or check the troubleshooting guide.

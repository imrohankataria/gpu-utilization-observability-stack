# Custom Prometheus Queries

This file contains useful Prometheus queries for GPU monitoring and analysis.

## GPU Utilization Queries

### Average GPU utilization across all GPUs
```promql
avg(DCGM_FI_DEV_GPU_UTIL)
```

### Per-GPU utilization
```promql
DCGM_FI_DEV_GPU_UTIL
```

### GPU idle percentage
```promql
100 - DCGM_FI_DEV_GPU_UTIL
```

### Average idle percentage
```promql
avg(100 - DCGM_FI_DEV_GPU_UTIL)
```

### GPUs below 20% utilization (idle)
```promql
count(DCGM_FI_DEV_GPU_UTIL < 20)
```

### GPU utilization over time (1 hour average)
```promql
avg_over_time(DCGM_FI_DEV_GPU_UTIL[1h])
```

## Memory (VRAM) Queries

### VRAM usage in bytes
```promql
DCGM_FI_DEV_FB_USED * 1024 * 1024
```

### VRAM usage percentage
```promql
(DCGM_FI_DEV_FB_USED / (DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE)) * 100
```

### Available VRAM
```promql
DCGM_FI_DEV_FB_FREE * 1024 * 1024
```

### Total VRAM capacity
```promql
(DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE) * 1024 * 1024
```

### GPUs with low memory utilization (<20%)
```promql
count((DCGM_FI_DEV_FB_USED / (DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE)) * 100 < 20)
```

## Cost Analysis Queries

### Estimated hourly waste ($2/hour per GPU)
```promql
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2)
```

### Estimated daily waste
```promql
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2 * 24)
```

### Estimated monthly waste
```promql
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2 * 24 * 30)
```

### Idle GPU hours over last 24 hours
```promql
sum(sum_over_time((100 - DCGM_FI_DEV_GPU_UTIL[24h])) / 100 / 60)
```

### Cost per instance
```promql
sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2) by (instance)
```

## Hardware Monitoring Queries

### GPU temperature
```promql
DCGM_FI_DEV_GPU_TEMP
```

### GPUs above 85°C
```promql
count(DCGM_FI_DEV_GPU_TEMP > 85)
```

### Power consumption (watts)
```promql
DCGM_FI_DEV_POWER_USAGE
```

### Total power consumption across all GPUs
```promql
sum(DCGM_FI_DEV_POWER_USAGE)
```

### Power efficiency (utilization per watt)
```promql
DCGM_FI_DEV_GPU_UTIL / DCGM_FI_DEV_POWER_USAGE
```

### GPU clock speeds
```promql
DCGM_FI_DEV_SM_CLOCK  # Streaming Multiprocessor clock
DCGM_FI_DEV_MEM_CLOCK # Memory clock
```

## Allocation and Distribution Queries

### Total number of GPUs
```promql
count(DCGM_FI_DEV_GPU_UTIL)
```

### GPUs per instance
```promql
count(DCGM_FI_DEV_GPU_UTIL) by (instance)
```

### Number of instances with GPUs
```promql
count(count(DCGM_FI_DEV_GPU_UTIL) by (instance))
```

### Average GPUs per instance
```promql
count(DCGM_FI_DEV_GPU_UTIL) / count(count(DCGM_FI_DEV_GPU_UTIL) by (instance))
```

### Active GPUs (>20% utilization)
```promql
count(DCGM_FI_DEV_GPU_UTIL > 20)
```

### Allocation efficiency (active vs total)
```promql
(count(DCGM_FI_DEV_GPU_UTIL > 20) / count(DCGM_FI_DEV_GPU_UTIL)) * 100
```

## Error and Health Queries

### XID errors (hardware errors)
```promql
DCGM_FI_DEV_XID_ERRORS
```

### XID error rate (per second)
```promql
rate(DCGM_FI_DEV_XID_ERRORS[5m])
```

### PCIe replay errors
```promql
DCGM_FI_DEV_PCIE_REPLAY_COUNTER
```

### Retired pages (memory errors)
```promql
DCGM_FI_DEV_RETIRED_DBE  # Double-bit errors
DCGM_FI_DEV_RETIRED_SBE  # Single-bit errors
```

## Trend Analysis Queries

### GPU utilization trend (compare current to 1 hour ago)
```promql
DCGM_FI_DEV_GPU_UTIL - DCGM_FI_DEV_GPU_UTIL offset 1h
```

### Memory usage trend
```promql
DCGM_FI_DEV_FB_USED - DCGM_FI_DEV_FB_USED offset 1h
```

### Utilization rate of change (per minute)
```promql
rate(DCGM_FI_DEV_GPU_UTIL[1m])
```

### Predict GPU utilization 4 hours ahead (linear regression)
```promql
predict_linear(DCGM_FI_DEV_GPU_UTIL[1h], 4*3600)
```

## Advanced Queries

### GPUs with high power but low utilization (inefficient)
```promql
DCGM_FI_DEV_POWER_USAGE > 200 and DCGM_FI_DEV_GPU_UTIL < 30
```

### Utilization histogram (5-minute buckets)
```promql
histogram_quantile(0.95, sum(rate(DCGM_FI_DEV_GPU_UTIL[5m])) by (le))
```

### Time spent in each utilization band (last 24h)
```promql
# Idle (0-20%)
sum(count_over_time((DCGM_FI_DEV_GPU_UTIL < 20)[24h:])) / 60

# Low (20-40%)
sum(count_over_time((DCGM_FI_DEV_GPU_UTIL >= 20 and DCGM_FI_DEV_GPU_UTIL < 40)[24h:])) / 60

# Medium (40-60%)
sum(count_over_time((DCGM_FI_DEV_GPU_UTIL >= 40 and DCGM_FI_DEV_GPU_UTIL < 60)[24h:])) / 60

# Good (60-80%)
sum(count_over_time((DCGM_FI_DEV_GPU_UTIL >= 60 and DCGM_FI_DEV_GPU_UTIL < 80)[24h:])) / 60

# Optimal (80-100%)
sum(count_over_time((DCGM_FI_DEV_GPU_UTIL >= 80)[24h:])) / 60
```

### Worst performing GPUs (most idle time)
```promql
topk(5, sum_over_time((100 - DCGM_FI_DEV_GPU_UTIL[24h])) / 100 / 60)
```

### Best performing GPUs (highest utilization)
```promql
topk(5, avg_over_time(DCGM_FI_DEV_GPU_UTIL[24h]))
```

## Recording Rules

You can create recording rules for expensive queries in `prometheus/rules.yml`:

```yaml
groups:
  - name: gpu_recording_rules
    interval: 30s
    rules:
      # Pre-calculate idle percentage
      - record: gpu:idle_percent
        expr: 100 - DCGM_FI_DEV_GPU_UTIL
      
      # Pre-calculate memory usage percentage
      - record: gpu:memory_percent
        expr: (DCGM_FI_DEV_FB_USED / (DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE)) * 100
      
      # Pre-calculate hourly cost
      - record: gpu:hourly_cost
        expr: sum((100 - DCGM_FI_DEV_GPU_UTIL) / 100 * 2)
      
      # Pre-calculate instance-level metrics
      - record: instance:gpu_count
        expr: count(DCGM_FI_DEV_GPU_UTIL) by (instance)
      
      - record: instance:avg_gpu_util
        expr: avg(DCGM_FI_DEV_GPU_UTIL) by (instance)
```

Then use the recorded metrics:
```promql
gpu:idle_percent
gpu:memory_percent
gpu:hourly_cost
```

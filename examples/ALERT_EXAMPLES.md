# Alert Configuration Examples

## Example 1: Slack Notifications

Configure AlertManager to send notifications to Slack:

```yaml
# alertmanager/alertmanager.yml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

receivers:
  - name: 'cost-optimization-team'
    slack_configs:
      - channel: '#gpu-cost-alerts'
        username: 'GPU Waste Bot'
        title: '💸 GPU Waste Alert'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          {{ if .Annotations.cost_impact }}*Cost Impact:* {{ .Annotations.cost_impact }}{{ end }}
          {{ if .Annotations.recommendation }}*Recommendation:* {{ .Annotations.recommendation }}{{ end }}
          *Severity:* {{ .Labels.severity }}
          {{ end }}
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
```

## Example 2: Email Notifications

Send email alerts for critical GPU issues:

```yaml
# alertmanager/alertmanager.yml
receivers:
  - name: 'ops-team'
    email_configs:
      - to: 'ops-team@company.com'
        from: 'gpu-alerts@company.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'gpu-alerts@company.com'
        auth_password: 'your-app-password'
        headers:
          Subject: '🚨 GPU Alert: {{ .GroupLabels.alertname }}'
        html: |
          <h2>GPU Alert Triggered</h2>
          {{ range .Alerts }}
          <p><strong>Summary:</strong> {{ .Annotations.summary }}</p>
          <p><strong>Description:</strong> {{ .Annotations.description }}</p>
          <p><strong>Severity:</strong> {{ .Labels.severity }}</p>
          {{ if .Annotations.recommendation }}
          <p><strong>Recommendation:</strong> {{ .Annotations.recommendation }}</p>
          {{ end }}
          <hr>
          {{ end }}
```

## Example 3: PagerDuty Integration

Route critical alerts to PagerDuty:

```yaml
# alertmanager/alertmanager.yml
receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_INTEGRATION_KEY'
        description: '{{ .GroupLabels.alertname }}: {{ .CommonAnnotations.summary }}'
        severity: '{{ .CommonLabels.severity }}'
        details:
          alert_count: '{{ .Alerts | len }}'
          firing_alerts: '{{ range .Alerts }}{{ .Labels.instance }} {{ end }}'

route:
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: false
```

## Example 4: Multiple Receivers

Send to different teams based on alert category:

```yaml
# alertmanager/alertmanager.yml
route:
  receiver: 'default'
  group_by: ['alertname', 'cluster']
  routes:
    # Cost/waste alerts to finance team
    - match:
        category: waste
      receiver: 'finance-team'
      continue: true
    
    # Infrastructure issues to ops team
    - match:
        category: vram_misuse
      receiver: 'ops-team'
    
    # Critical hardware to on-call
    - match:
        severity: critical
        category: hardware
      receiver: 'oncall-pagerduty'

receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
  
  - name: 'finance-team'
    slack_configs:
      - channel: '#gpu-costs'
        title: '💰 GPU Cost Alert'
  
  - name: 'ops-team'
    slack_configs:
      - channel: '#gpu-ops'
        title: '⚙️ GPU Operations Alert'
  
  - name: 'oncall-pagerduty'
    pagerduty_configs:
      - service_key: 'ONCALL_KEY'
```

## Example 5: Alert Throttling

Prevent alert fatigue with time-based grouping:

```yaml
# alertmanager/alertmanager.yml
route:
  receiver: 'default'
  group_wait: 30s        # Wait 30s before sending first notification
  group_interval: 5m     # Wait 5m before sending updates
  repeat_interval: 4h    # Resend alert every 4h if still firing
  
  routes:
    # Less urgent alerts - throttle more
    - match:
        severity: warning
      group_wait: 2m
      group_interval: 10m
      repeat_interval: 12h
    
    # Critical alerts - send immediately
    - match:
        severity: critical
      group_wait: 10s
      group_interval: 1m
      repeat_interval: 1h
```

## Testing Alert Configuration

Test your AlertManager configuration:

```bash
# Validate configuration
docker exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml

# Send test alert
curl -H "Content-Type: application/json" -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  },
  "annotations": {
    "summary": "This is a test alert",
    "description": "Testing alert routing"
  }
}]' http://localhost:9093/api/v1/alerts

# View active alerts
curl http://localhost:9093/api/v1/alerts
```

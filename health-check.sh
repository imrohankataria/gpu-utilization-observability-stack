#!/bin/bash

# GPU Observability Stack - Health Check Script

echo "🏥 GPU Observability Stack - Health Check"
echo "=========================================="
echo ""

# Function to check if a service is healthy
check_service() {
    local service=$1
    local port=$2
    local name=$3
    
    if docker-compose ps | grep -q "$service.*Up"; then
        echo "✅ $name is running"
        if nc -z localhost $port 2>/dev/null; then
            echo "   ✓ Port $port is accessible"
        else
            echo "   ⚠️  Port $port is not accessible"
        fi
    else
        echo "❌ $name is not running"
    fi
    echo ""
}

# Check Docker services
echo "📋 Service Status:"
echo "------------------"
docker-compose ps
echo ""

# Check individual services
echo "🔍 Detailed Service Checks:"
echo "---------------------------"
check_service "dcgm-exporter" 9400 "DCGM Exporter"
check_service "prometheus" 9090 "Prometheus"
check_service "grafana" 3000 "Grafana"
check_service "alertmanager" 9093 "AlertManager"

# Check GPU access
echo "🎮 GPU Detection:"
echo "-----------------"
if command -v nvidia-smi &> /dev/null; then
    echo "✅ nvidia-smi is available"
    echo ""
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv
    echo ""
else
    echo "⚠️  nvidia-smi not found on host"
    echo ""
fi

# Check DCGM metrics
echo "📊 DCGM Metrics Check:"
echo "----------------------"
if curl -s http://localhost:9400/metrics | grep -q "DCGM_FI_DEV_GPU_UTIL"; then
    echo "✅ DCGM metrics are being collected"
    GPU_COUNT=$(curl -s http://localhost:9400/metrics | grep "DCGM_FI_DEV_GPU_UTIL{" | wc -l)
    echo "   ✓ Detected $GPU_COUNT GPU(s)"
else
    echo "❌ DCGM metrics not available"
    echo "   Try: docker logs dcgm-exporter"
fi
echo ""

# Check Prometheus targets
echo "🎯 Prometheus Scrape Targets:"
echo "------------------------------"
if curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -q "dcgm"; then
    echo "✅ Prometheus is scraping DCGM exporter"
else
    echo "❌ Prometheus is not scraping DCGM exporter"
fi
echo ""

# Check Grafana health
echo "📈 Grafana Status:"
echo "------------------"
if curl -s http://localhost:3000/api/health 2>/dev/null | grep -q "ok"; then
    echo "✅ Grafana is healthy"
else
    echo "⚠️  Grafana health check failed"
fi
echo ""

# Check alert rules
echo "🚨 Alert Rules Status:"
echo "----------------------"
ALERT_COUNT=$(curl -s http://localhost:9090/api/v1/rules 2>/dev/null | grep -o '"alerts":\[' | wc -l)
if [ "$ALERT_COUNT" -gt 0 ]; then
    echo "✅ Alert rules are loaded"
    echo "   ✓ $ALERT_COUNT rule groups active"
else
    echo "⚠️  No alert rules detected"
fi
echo ""

# Summary
echo "📊 Summary:"
echo "-----------"
if docker-compose ps | grep -q "Exit"; then
    echo "⚠️  Some services have exited. Run 'docker-compose logs' to investigate."
else
    echo "✅ All core services appear to be running"
fi
echo ""
echo "🔗 Quick Links:"
echo "   - Grafana:      http://localhost:3000"
echo "   - Prometheus:   http://localhost:9090"
echo "   - AlertManager: http://localhost:9093"
echo "   - DCGM Metrics: http://localhost:9400/metrics"
echo ""
echo "💡 Troubleshooting:"
echo "   - View logs: docker-compose logs -f [service-name]"
echo "   - Restart:   docker-compose restart [service-name]"
echo "   - Rebuild:   docker-compose up -d --force-recreate"
echo ""

#!/bin/bash

# GPU Observability Stack - Quick Start Script
set -e

echo "🚀 GPU Utilization Observability Stack - Quick Start"
echo "===================================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if NVIDIA Docker runtime is available
echo "🔍 Checking NVIDIA Docker runtime..."
if ! docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi &> /dev/null; then
    echo "⚠️  NVIDIA Container Toolkit not detected or not configured properly."
    echo "   Please install NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    echo ""
    echo "   Quick install (Ubuntu/Debian):"
    echo "   1. distribution=\$(. /etc/os-release;echo \$ID\$VERSION_ID)"
    echo "   2. curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -"
    echo "   3. curl -s -L https://nvidia.github.io/nvidia-docker/\$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list"
    echo "   4. sudo apt-get update && sudo apt-get install -y nvidia-docker2"
    echo "   5. sudo systemctl restart docker"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "✅ Prerequisites check passed!"
echo ""

# Create data directories
echo "📁 Creating data directories..."
mkdir -p prometheus_data grafana_data

# Start the stack
echo "🐳 Starting GPU Observability Stack..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo ""
echo "🔍 Checking service status..."
docker-compose ps

echo ""
echo "✅ GPU Observability Stack is running!"
echo ""
echo "📊 Access your dashboards:"
echo "   - Grafana:       http://localhost:3000 (admin/admin)"
echo "   - Prometheus:    http://localhost:9090"
echo "   - AlertManager:  http://localhost:9093"
echo ""
echo "🎯 Pre-built dashboards available in Grafana:"
echo "   1. GPU Utilization Dashboard"
echo "   2. GPU Cost Analysis - Waste & Savings"
echo "   3. GPU Utilization Heatmap"
echo "   4. GPU Container Allocation"
echo ""
echo "⚙️  Next steps:"
echo "   1. Open Grafana at http://localhost:3000"
echo "   2. Login with admin/admin (change password when prompted)"
echo "   3. Navigate to Dashboards → Browse to see GPU metrics"
echo "   4. Customize cost parameters in Cost Analysis dashboard"
echo "   5. Configure alert notifications in alertmanager/alertmanager.yml"
echo ""
echo "📖 For detailed documentation, see README.md"
echo ""
echo "🛑 To stop the stack: docker-compose down"
echo "🔄 To restart: docker-compose restart"
echo "📋 To view logs: docker-compose logs -f"
echo ""

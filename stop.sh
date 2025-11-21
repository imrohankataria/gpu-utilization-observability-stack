#!/bin/bash

# GPU Observability Stack - Stop Script
set -e

echo "🛑 Stopping GPU Observability Stack..."
echo ""

# Stop all containers
docker-compose down

echo ""
echo "✅ All services stopped!"
echo ""
echo "💡 Tips:"
echo "   - To start again: ./start.sh or docker-compose up -d"
echo "   - To remove all data volumes: docker-compose down -v"
echo "   - To view stopped containers: docker-compose ps -a"
echo ""

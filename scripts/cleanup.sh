#!/bin/bash
# SCION MiniNet Cleanup Script
# Removes all generated files and stops containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🧹 Cleaning up SCION MiniNet..."

# Stop and remove containers
echo "🛑 Stopping containers..."
cd "$PROJECT_DIR"
docker compose down -v --remove-orphans 2>/dev/null || true

# Remove generated files
echo "🗑️  Removing generated files..."
rm -rf "$PROJECT_DIR/gen"

echo "✅ Cleanup complete!"

.PHONY: help setup up down logs status paths ping measure shell-111 shell-211 break-link restore-link clean visualizer

# Default target
help:
	@echo "SCION MiniNet - Local SCION Network for Learning"
	@echo ""
	@echo "Setup & Lifecycle:"
	@echo "  make setup       - Generate topology configurations"
	@echo "  make build       - Build the SCION Docker image"
	@echo "  make up          - Start the SCION network"
	@echo "  make down        - Stop the SCION network"
	@echo "  make restart     - Restart the network"
	@echo "  make clean       - Remove all generated files and containers"
	@echo ""
	@echo "Monitoring:"
	@echo "  make status      - Show container status"
	@echo "  make logs        - Tail all container logs"
	@echo "  make logs-111    - Tail logs for AS 1-ff00:0:111"
	@echo "  make logs-211    - Tail logs for AS 2-ff00:0:211"
	@echo ""
	@echo "SCION Tools (from host-111):"
	@echo "  make paths       - Show paths from AS111 to AS211"
	@echo "  make ping        - Ping from AS111 to AS211"
	@echo "  make measure     - Measure latency on all paths"
	@echo ""
	@echo "Interactive:"
	@echo "  make shell-111   - Shell into host in AS 1-ff00:0:111"
	@echo "  make shell-211   - Shell into host in AS 2-ff00:0:211"
	@echo ""
	@echo "Experiments:"
	@echo "  make break-link ROUTER=router-110  - Stop a router to simulate failure"
	@echo "  make restore-link ROUTER=router-110 - Restart a stopped router"
	@echo ""
	@echo "Visualizer:"
	@echo "  make visualizer  - Start the web-based GUI visualizer"

# ============================================
# Setup & Lifecycle
# ============================================

setup:
	@echo "🔧 Generating SCION topology configurations..."
	@./scripts/setup.sh
	@echo "✅ Setup complete! Run 'make build' to build the Docker image."

build:
	@echo "🔨 Building SCION Docker image..."
	docker compose build
	@echo "✅ Image built! Run 'make up' to start the network."

up:
	@echo "🚀 Starting SCION network..."
	docker compose up -d
	@echo "⏳ Waiting for services to initialize..."
	@sleep 15
	@echo "✅ Network is up! Run 'make status' to check."

down:
	@echo "🛑 Stopping SCION network..."
	docker compose down

restart: down up

clean:
	@echo "🧹 Cleaning up..."
	docker compose down -v --remove-orphans 2>/dev/null || true
	rm -rf gen/
	@echo "✅ Cleanup complete."

# ============================================
# Monitoring
# ============================================

status:
	@echo "📊 Container Status:"
	@docker compose ps

logs:
	docker compose logs -f

logs-111:
	docker compose logs -f cs-111 router-111 daemon-111 host-111

logs-211:
	docker compose logs -f cs-211 router-211 daemon-211 host-211

# ============================================
# SCION Tools
# ============================================

# Show available paths from AS111 to AS211
paths:
	@echo "🔍 Discovering paths from 1-ff00:0:111 to 2-ff00:0:211..."
	@./bin/scion-paths

# Ping from AS111 to AS211
ping:
	@echo "🏓 Pinging from 1-ff00:0:111 to 2-ff00:0:211..."
	@./bin/scion-ping

# Measure latency on all paths
measure:
	@echo "📏 Measuring latency on all available paths..."
	@./bin/scion-measure

# Interactive path selection and ping
interactive:
	@./bin/scion-interactive

# ============================================
# Interactive Shells
# ============================================

shell-111:
	@echo "🐚 Opening shell in AS 1-ff00:0:111..."
	docker exec -it scion-as111 /bin/bash

shell-211:
	@echo "🐚 Opening shell in AS 2-ff00:0:211..."
	docker exec -it scion-as211 /bin/bash

# ============================================
# Experiments
# ============================================

break-link:
ifndef ROUTER
	@echo "❌ Usage: make break-link ROUTER=router-110"
	@exit 1
endif
	@echo "💥 Stopping $(ROUTER) to simulate link failure..."
	docker compose stop $(ROUTER)
	@echo "⚠️  Router $(ROUTER) stopped. Run 'make paths' to see updated routes."

restore-link:
ifndef ROUTER
	@echo "❌ Usage: make restore-link ROUTER=router-110"
	@exit 1
endif
	@echo "🔄 Restarting $(ROUTER)..."
	docker compose start $(ROUTER)
	@echo "✅ Router $(ROUTER) restored. Paths will update shortly."

# ============================================
# GUI Visualizer
# ============================================

visualizer:
	@echo "🌐 Starting SCION Network Visualizer..."
	@echo ""
	@echo "   Installing dependencies (if needed)..."
	@pip3 install -q flask flask-cors 2>/dev/null || pip install -q flask flask-cors
	@echo ""
	@echo "   Open http://localhost:8080 in your browser"
	@echo "   Press Ctrl+C to stop the server"
	@echo ""
	@python3 visualizer/server.py


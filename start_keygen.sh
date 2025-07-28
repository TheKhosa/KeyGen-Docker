#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check Docker Compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif docker-compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

print_info "Using: ${DOCKER_COMPOSE_CMD}"

# Step 1: Generate Caddyfile
print_info "Generating Caddyfile..."
${DOCKER_COMPOSE_CMD} --profile config run --rm caddy-config

# Verify Caddyfile was created
if [ ! -f "Caddyfile" ]; then
    print_error "Failed to generate Caddyfile"
    exit 1
fi

print_success "Caddyfile generated successfully"

# Step 2: Clean up any existing containers
print_info "Cleaning up existing containers..."
${DOCKER_COMPOSE_CMD} down -v --remove-orphans 2>/dev/null || true

# Step 3: Start databases first
print_info "Starting databases..."
${DOCKER_COMPOSE_CMD} up -d postgres redis

# Step 4: Wait for databases
print_info "Waiting for databases to be ready..."
sleep 20

# Check database health
until ${DOCKER_COMPOSE_CMD} exec postgres pg_isready -U keygen -d keygen_production; do
    print_info "Waiting for PostgreSQL..."
    sleep 5
done

# Step 5: Run setup
print_info "Running Keygen setup..."
${DOCKER_COMPOSE_CMD} --profile setup run --rm setup

# Step 6: Start all services
print_info "Starting all services..."
${DOCKER_COMPOSE_CMD} up -d

# Step 7: Wait for services
print_info "Waiting for services to be ready..."
sleep 30

# Step 8: Check status
print_info "Checking service status..."
${DOCKER_COMPOSE_CMD} ps

# Step 9: Test API
print_info "Testing API endpoint..."
for i in {1..10}; do
    if curl -f -s "http://localhost:3000/v1/health" > /dev/null 2>&1; then
        print_success "API is responding!"
        break
    else
        print_info "Waiting for API... (attempt $i/10)"
        sleep 10
    fi
done

# Final status
echo ""
echo "================================================"
echo "           Keygen Setup Complete!"
echo "================================================"
echo ""
echo "Services Status:"
${DOCKER_COMPOSE_CMD} ps
echo ""
echo "Access URLs:"
echo "  API Endpoint: https://api.efret.io"
echo "  Health Check: http://localhost:3000/v1/health"
echo ""
echo "Admin Credentials:"
if [ -f .env ]; then
    ADMIN_EMAIL=$(grep KEYGEN_ADMIN_EMAIL .env | cut -d'=' -f2)
    ADMIN_PASSWORD=$(grep KEYGEN_ADMIN_PASSWORD .env | cut -d'=' -f2)
    echo "  Email: ${ADMIN_EMAIL}"
    echo "  Password: ${ADMIN_PASSWORD}"
fi
echo ""
echo "Useful Commands:"
echo "  View logs:    ${DOCKER_COMPOSE_CMD} logs -f"
echo "  Stop all:     ${DOCKER_COMPOSE_CMD} down"
echo "  Restart:      ${DOCKER_COMPOSE_CMD} restart"
echo "================================================"

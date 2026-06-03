#!/bin/bash
# DriveGo - Start all services
# Usage: ./start.sh [dev|prod]

MODE=${1:-dev}

echo "Starting DriveGo services..."

# Kill existing
kill $(lsof -t -i:8000) 2>/dev/null
kill $(lsof -t -i:3001) 2>/dev/null
kill $(lsof -t -i:3002) 2>/dev/null
sleep 1

# Backend Laravel
echo "[1/3] Starting Laravel backend on :8000..."
cd /root/DriveGo/backend
setsid php artisan serve --host=0.0.0.0 --port=8000 < /dev/null > /tmp/laravel-server.log 2>&1 &
disown

# Realtime Node.js
echo "[2/3] Starting Realtime server on :3001..."
cd /root/DriveGo/realtime
setsid node src/index.js < /dev/null > /tmp/realtime.log 2>&1 &
disown

# Admin React
echo "[3/3] Starting Admin dashboard on :3002..."
cd /root/DriveGo/admin
if [ "$MODE" = "prod" ]; then
    npm run build > /dev/null 2>&1
    setsid npm run preview < /dev/null > /tmp/admin-server.log 2>&1 &
else
    setsid npm run dev -- --host=0.0.0.0 < /dev/null > /tmp/admin-server.log 2>&1 &
fi
disown

sleep 3

# Verify
echo ""
echo "=== Verification ==="
echo -n "Laravel :8000 .. "
curl -sf http://localhost:8000/api/drivers > /dev/null && echo "OK" || echo "FAIL"
echo -n "Realtime :3001 .. "
curl -sf http://localhost:3001/health > /dev/null && echo "OK" || echo "FAIL"
echo -n "Admin :3002 .. "
curl -sf http://localhost:3002 > /dev/null && echo "OK" || echo "FAIL"

echo ""
echo "All services running:"
echo "  Backend:   http://localhost:8000"
echo "  Realtime:  http://localhost:3001"
echo "  Admin:     http://localhost:3002"
echo ""
echo "Admin login: 08120000000 / admin123"
echo "Customer login: 08123456789 / password123"
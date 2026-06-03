#!/bin/bash
# Keep SSH tunnel alive for DriveGo backend
# Usage: nohup bash /root/DriveGo/tunnel.sh &

TUNNEL_LOG=/tmp/drivego-tunnel.log

while true; do
  echo "[$(date)] Starting tunnel..." >> $TUNNEL_LOG
  ssh -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      -o ExitOnForwardFailure=yes \
      -R 80:localhost:8000 \
      nokey@localhost.run >> $TUNNEL_LOG 2>&1
  echo "[$(date)] Tunnel died, restarting in 5s..." >> $TUNNEL_LOG
  sleep 5
done
#!/usr/bin/env bash
# deploy.sh — Deploy GoThere landing page to server
# Usage: ./deploy.sh
#
# Prerequisites:
#   - SSH key at ~/.ssh/lightsail.pem
#   - Server: gabriel@54.152.75.2
#   - Nginx installed and configured on server

set -euo pipefail

SERVER="gabriel"  # SSH config alias -> ubuntu@54.152.75.2
REMOTE_DIR="/var/www/gothere-landing"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Attribution gate: App Store links must carry pt/ct (utm_* is ignored by Apple)
# and Play links must carry a url-encoded `referrer=`. See
# Projects/GoThere/_marketing/paid/audit_store_links.py
AUDIT="$HOME/Projects/GoThere/_marketing/paid/audit_store_links.py"
if [ -f "$AUDIT" ]; then
  echo "==> Checking store-link attribution"
  if ! python "$AUDIT" --app gothere | tee /dev/stderr | grep -q "TOTAL unattributed store links: 0"; then
    echo "ABORT: untagged store links found. Run: python \"$AUDIT\" --fix --app gothere"
    exit 1
  fi
fi

echo "==> Deploying GoThere landing page to $SERVER:$REMOTE_DIR"

# Create remote directory if it doesn't exist
ssh "$SERVER" "sudo mkdir -p $REMOTE_DIR && sudo chown ubuntu:ubuntu $REMOTE_DIR"

# Sync files
rsync -avz --delete \
  -e "ssh" \
  --exclude='deploy.sh' \
  --exclude='nginx.conf' \
  --exclude='.DS_Store' \
  --exclude='*.sh' \
  "$LOCAL_DIR/" \
  "$SERVER:$REMOTE_DIR/"

echo "==> Files synced successfully"

# Copy nginx config and reload
ssh "$SERVER" "sudo cp $REMOTE_DIR/../gothere-nginx.conf /etc/nginx/sites-available/gothere 2>/dev/null || true"
ssh "$SERVER" "sudo ln -sf /etc/nginx/sites-available/gothere /etc/nginx/sites-enabled/gothere 2>/dev/null || true"
ssh "$SERVER" "sudo nginx -t && sudo systemctl reload nginx"

echo "==> Deployment complete"
echo "    Site: https://gothere.app (or http://54.152.75.2)"

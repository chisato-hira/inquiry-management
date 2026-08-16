#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
SSH_KEY="$HOME/.ssh/inquiry-management-key"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=accept-new"

EC2_IP=$(terraform -chdir="$TF_DIR" output -raw ec2_public_ip)
echo "==> デプロイ先EC2: $EC2_IP"

# --- 1. frontendをローカルでビルド ---
echo "==> frontendをビルド中..."
(cd "$REPO_ROOT/frontend" && npm install && npm run build)
DIST_DIR="$REPO_ROOT/frontend/dist"
[ -d "$DIST_DIR" ] || { echo "distが見つかりません: $DIST_DIR" >&2; exit 1; }

# --- 2. ビルド成果物をEC2へ転送(/opt/appはec2-user所有なのでsudo不要) ---
echo "==> frontendをEC2へ転送中..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "rm -rf /opt/app/frontend/dist && mkdir -p /opt/app/frontend/dist"
scp $SSH_OPTS -r "$DIST_DIR"/* "ec2-user@$EC2_IP:/opt/app/frontend/dist/"
# nginxはnginxユーザーで実行されるため、他者(other)からの読み取り権限を保証しておく
ssh $SSH_OPTS "ec2-user@$EC2_IP" "chmod -R o+rX /opt/app/frontend"

# --- 3. nginx設定を配置(初回はデフォルト設定を退避してから配置) ---
echo "==> nginx設定を配置中..."
scp $SSH_OPTS "$REPO_ROOT/deploy/nginx/inquiry-management.conf" "ec2-user@$EC2_IP:/tmp/inquiry-management.conf"
ssh $SSH_OPTS "ec2-user@$EC2_IP" '
  sudo mv /tmp/inquiry-management.conf /etc/nginx/conf.d/inquiry-management.conf &&
  if [ -f /etc/nginx/conf.d/default.conf ]; then
    sudo mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
  fi &&
  sudo nginx -t &&
  sudo systemctl reload nginx
'

# --- 4. 起動確認 ---
echo "==> 起動確認中..."
if curl -sf "http://$EC2_IP/" > /dev/null; then
  echo "✅ frontend配信確認OK: http://$EC2_IP/"
else
  echo "❌ frontend確認に失敗。確認コマンド:"
  echo "   ssh $SSH_OPTS ec2-user@$EC2_IP 'sudo nginx -t && sudo systemctl status nginx'"
  exit 1
fi

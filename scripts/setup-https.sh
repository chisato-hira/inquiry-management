#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
SSH_KEY="$HOME/.ssh/inquiry-management-key"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=accept-new"

EC2_IP=$(terraform -chdir="$TF_DIR" output -raw ec2_public_ip)
DUCKDNS_DOMAIN=$(grep '^duckdns_domain' "$TF_DIR/terraform.tfvars" | sed -E 's/.*"(.*)".*/\1/')
DUCKDNS_TOKEN=$(grep '^duckdns_token' "$TF_DIR/terraform.tfvars" | sed -E 's/.*"(.*)".*/\1/')

echo "==> デプロイ先EC2: $EC2_IP"
echo "==> 証明書発行対象ドメイン: $DUCKDNS_DOMAIN"

# --- 1. certbotをインストール(既にインストール済みでも安全に実行できる) ---
echo "==> certbotをインストール中..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "sudo dnf install -y certbot"

# --- 2. DuckDNSトークンをEC2上に安全に配置(root専用、600権限) ---
echo "==> DuckDNSトークンを配置中..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "sudo mkdir -p /etc/duckdns"
echo "$DUCKDNS_TOKEN" | ssh $SSH_OPTS "ec2-user@$EC2_IP" "sudo tee /etc/duckdns/token > /dev/null && sudo chmod 600 /etc/duckdns/token && sudo chown root:root /etc/duckdns/token"

# --- 3. DNS-01用のフックスクリプトを配置 ---
echo "==> certbotフックスクリプトを配置中..."
scp $SSH_OPTS "$REPO_ROOT/deploy/certbot/duckdns-auth-hook.sh" "ec2-user@$EC2_IP:/tmp/duckdns-auth-hook.sh"
scp $SSH_OPTS "$REPO_ROOT/deploy/certbot/duckdns-cleanup-hook.sh" "ec2-user@$EC2_IP:/tmp/duckdns-cleanup-hook.sh"
ssh $SSH_OPTS "ec2-user@$EC2_IP" "
  sudo mv /tmp/duckdns-auth-hook.sh /etc/duckdns/auth-hook.sh &&
  sudo mv /tmp/duckdns-cleanup-hook.sh /etc/duckdns/cleanup-hook.sh &&
  sudo chmod 700 /etc/duckdns/auth-hook.sh /etc/duckdns/cleanup-hook.sh &&
  sudo chown root:root /etc/duckdns/auth-hook.sh /etc/duckdns/cleanup-hook.sh
"

# --- 4. 証明書を取得(初回のみ。既に存在する場合はスキップ) ---
echo "==> Let's Encrypt証明書を取得中(DNS-01、伝播待ちを含め数分かかります)..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "
  if sudo test -f /etc/letsencrypt/live/${DUCKDNS_DOMAIN}/fullchain.pem; then
    echo '証明書は既に存在します。取得をスキップします。'
  else
    sudo certbot certonly \
      --manual \
      --preferred-challenges dns \
      --manual-auth-hook /etc/duckdns/auth-hook.sh \
      --manual-cleanup-hook /etc/duckdns/cleanup-hook.sh \
      -d ${DUCKDNS_DOMAIN} \
      --non-interactive --agree-tos --register-unsafely-without-email
  fi
"

# --- 5. nginx設定をHTTPS版に切り替え ---
echo "==> nginx設定(HTTPS)を配置中..."
scp $SSH_OPTS "$REPO_ROOT/deploy/nginx/inquiry-management-https.conf" "ec2-user@$EC2_IP:/tmp/inquiry-management.conf"
ssh $SSH_OPTS "ec2-user@$EC2_IP" "
  sudo mv /tmp/inquiry-management.conf /etc/nginx/conf.d/inquiry-management.conf &&
  sudo nginx -t &&
  sudo systemctl reload nginx
"

# --- 6. 証明書の自動更新をsystemdタイマーで設定 ---
echo "==> 証明書の自動更新(1日2回のタイマー)を設定中..."
scp $SSH_OPTS "$REPO_ROOT/deploy/systemd/certbot-renew.service" "ec2-user@$EC2_IP:/tmp/certbot-renew.service"
scp $SSH_OPTS "$REPO_ROOT/deploy/systemd/certbot-renew.timer" "ec2-user@$EC2_IP:/tmp/certbot-renew.timer"
ssh $SSH_OPTS "ec2-user@$EC2_IP" "
  sudo mv /tmp/certbot-renew.service /etc/systemd/system/certbot-renew.service &&
  sudo mv /tmp/certbot-renew.timer /etc/systemd/system/certbot-renew.timer &&
  sudo systemctl daemon-reload &&
  sudo systemctl enable --now certbot-renew.timer
"

# --- 7. 動作確認 ---
echo "==> HTTPS動作確認中..."
if curl -sf "https://${DUCKDNS_DOMAIN}/" > /dev/null; then
  echo "✅ HTTPS確認OK: https://${DUCKDNS_DOMAIN}/"
else
  echo "❌ HTTPS確認に失敗。ログ確認コマンド:"
  echo "   ssh $SSH_OPTS ec2-user@$EC2_IP 'sudo journalctl -u certbot-renew -n 50 --no-pager; sudo nginx -t'"
  exit 1
fi

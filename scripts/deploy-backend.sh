#!/bin/bash
set -euo pipefail

# --- リポジトリのルートディレクトリを基準にする ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
BACKEND_DIR="$REPO_ROOT/backend"
SSH_KEY="$HOME/.ssh/inquiry-management-key"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=accept-new"

# --- Terraformの出力からEC2のIPとRDSのエンドポイントを取得 ---
EC2_IP=$(terraform -chdir="$TF_DIR" output -raw ec2_public_ip)
RDS_ENDPOINT=$(terraform -chdir="$TF_DIR" output -raw rds_endpoint)
RDS_HOST="${RDS_ENDPOINT%%:*}"

# --- terraform.tfvarsからDBパスワードを読み取る(gitignore済み・コミットされないファイル) ---
DB_PASSWORD=$(grep '^db_password' "$TF_DIR/terraform.tfvars" | sed -E 's/.*"(.*)".*/\1/')

echo "==> デプロイ先EC2: $EC2_IP"
echo "==> 接続先RDS: $RDS_HOST"

# --- 1. .env.productionを生成(gitignore対象。backend/config/database.ymlが読む環境変数を含む) ---
echo "==> .env.productionを生成中..."
cat > "$BACKEND_DIR/.env.production" <<EOF
RAILS_ENV=production
DB_HOST=${RDS_HOST}
DB_PORT=3306
BACKEND_DATABASE_PASSWORD=${DB_PASSWORD}
SOLID_QUEUE_IN_PUMA=true
EOF

# --- 2. backendのソース一式をEC2へ転送(.git・log・tmp・storage・.bundleは除外) ---
echo "==> backendをEC2へ転送中..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "mkdir -p /opt/app/backend"
rsync -az --delete \
  --exclude='.git' --exclude='log/*' --exclude='tmp/*' \
  --exclude='storage/*' --exclude='.bundle' --exclude='node_modules' \
  -e "ssh $SSH_OPTS" \
  "$BACKEND_DIR/" "ec2-user@$EC2_IP:/opt/app/backend/"

# --- 3. gem install(開発・テスト用gemは除外) ---
echo "==> bundle installを実行中(初回は数分かかります)..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "
  cd /opt/app/backend &&
  bundle config set --local without 'development test' &&
  bundle install
"

# --- 4. DBスキーマを準備(初回はdb:create相当も含めて実行される) ---
echo "==> db:prepareを実行中..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "
  cd /opt/app/backend &&
  set -a && source .env.production && set +a &&
  bundle exec rails db:prepare
"

# --- 5. systemdユニットを配置 ---
echo "==> systemdユニットを配置中..."
scp $SSH_OPTS "$REPO_ROOT/deploy/systemd/inquiry-management-backend.service" "ec2-user@$EC2_IP:/tmp/inquiry-management-backend.service"
ssh $SSH_OPTS "ec2-user@$EC2_IP" "sudo mv /tmp/inquiry-management-backend.service /etc/systemd/system/inquiry-management-backend.service && sudo systemctl daemon-reload"

# --- 6. サービスを起動・自動起動を有効化 ---
echo "==> backendサービスを(再)起動中..."
ssh $SSH_OPTS "ec2-user@$EC2_IP" "sudo systemctl enable inquiry-management-backend && sudo systemctl restart inquiry-management-backend"

# --- 7. 起動確認(固定sleepではなくリトライする) ---
echo "==> 起動確認中(最大60秒、5秒間隔でリトライ)..."
for i in $(seq 1 12); do
  if curl -sf "http://$EC2_IP:3000/up" > /dev/null; then
    echo "✅ backend起動確認OK: http://$EC2_IP:3000/up"
    exit 0
  fi
  sleep 5
done

echo "❌ backend起動確認に失敗(60秒待っても応答なし)。ログ確認コマンド:"
echo "   ssh $SSH_OPTS ec2-user@$EC2_IP 'sudo journalctl -u inquiry-management-backend -n 50 --no-pager'"
exit 1

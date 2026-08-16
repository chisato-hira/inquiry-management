#!/bin/bash
# certbotのDNS-01チャレンジ用authフック。
# certbotが CERTBOT_DOMAIN・CERTBOT_VALIDATION を環境変数として渡してくる。
# トークンは環境変数ではなく /etc/duckdns/token (root専用、600権限) から読む
# (certbot renewを自動実行するcron/systemdタイマーの環境にトークンが無くても動くようにするため)。
set -euo pipefail

DUCKDNS_TOKEN=$(cat /etc/duckdns/token)
SUBDOMAIN="${CERTBOT_DOMAIN%%.duckdns.org}"

curl -fsS "https://www.duckdns.org/update?domains=${SUBDOMAIN}&token=${DUCKDNS_TOKEN}&txt=${CERTBOT_VALIDATION}" > /tmp/duckdns-update-result

# DuckDNSは成功時に本文"OK"を返す
if ! grep -q "^OK" /tmp/duckdns-update-result; then
  echo "DuckDNSのTXTレコード更新に失敗しました: $(cat /tmp/duckdns-update-result)" >&2
  exit 1
fi

# DNS伝播待ち
sleep 30

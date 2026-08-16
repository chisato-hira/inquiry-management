#!/bin/bash
# certbotのDNS-01チャレンジ用cleanupフック。TXTレコードを空にする。
set -euo pipefail

DUCKDNS_TOKEN=$(cat /etc/duckdns/token)
SUBDOMAIN="${CERTBOT_DOMAIN%%.duckdns.org}"

curl -fsS "https://www.duckdns.org/update?domains=${SUBDOMAIN}&token=${DUCKDNS_TOKEN}&txt=cleared&clear=true" > /dev/null || true

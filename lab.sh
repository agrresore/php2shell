#!/bin/bash
# Quick lab setup: official php:8.4.26-apache + stock php.ini-production.
# Single prefork worker, display_errors=Off, memory_limit=128M.
#
# Usage:
#   ./lab.sh              # start lab on port 18110
#   ./lab.sh --stop       # stop and remove container
#   PORT=8088 ./lab.sh    # custom port
set -eu

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  DOCKER=docker
elif DOCKER_HOST=unix:///Users/$(whoami)/.docker/run/docker.sock docker info &>/dev/null 2>&1; then
  export DOCKER_HOST=unix:///Users/$(whoami)/.docker/run/docker.sock
  DOCKER=docker
else
  DOCKER="sudo docker"
fi

IMAGE=${IMAGE:-php:8.4.26-apache}
NAME=${NAME:-php2shell-target}
PORT=${PORT:-18110}

if [ "${1:-}" = "--stop" ]; then
  $DOCKER rm -f "$NAME" 2>/dev/null || true
  echo "stopped $NAME"
  exit 0
fi

$DOCKER rm -f "$NAME" >/dev/null 2>&1 || true
mkdir -p "$HERE/out"

$DOCKER run -d --name "$NAME" \
  -p "127.0.0.1:$PORT:80" \
  -v "$HERE/docker/apache.conf:/etc/apache2/conf-enabled/zz-p2s.conf:ro" \
  -v "$HERE/docker/www:/var/www/html:ro" \
  -v "$HERE/out:/out" \
  "$IMAGE" /bin/sh -c \
  'cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini;
   chown -R www-data:www-data /out 2>/dev/null || true;
   exec apache2-foreground' >/dev/null

# Wait for target to respond
for _ in $(seq 1 30); do
  if curl -s -m 2 "http://127.0.0.1:$PORT/index.php" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo "=== php2shell lab ==="
echo "target: http://127.0.0.1:$PORT/index.php"
$DOCKER exec "$NAME" php -v | head -1
echo ""
echo "config:"
$DOCKER exec "$NAME" php -i 2>/dev/null | \
  grep -E '^display_errors|^memory_limit|^post_max_size|^session.use_strict_mode|^session.upload_progress.enabled' | head -10
echo ""
echo "extract offsets:"
echo "  python3 -c \"from lib.offsets import *; z,d = extract_from_container('$NAME'); print(f'zif=0x{z:x} dtor=0x{d:x}'); save_offsets_env('out/offsets.env', z, d)\""
echo ""
echo "run exploit:"
echo "  python3 exploit.py --target http://127.0.0.1:$PORT/index.php --cmd 'id>/out/p1' --proof out/p1 --restart $NAME"

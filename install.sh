#!/bin/bash
# ================================================================
#  D — paste in console:
#
#  bash <(curl -sL https://raw.githubusercontent.com/Afonya876/xcad7f34fe5f6/main/install.sh)
# ================================================================
set -e
REPO_RAW="https://raw.githubusercontent.com/Afonya876/xcad7f34fe5f6/main"
CURL="curl -sL"
[ -n "$GH_TOKEN" ] && CURL="curl -sL -H \"Authorization: token $GH_TOKEN\""
BASE="/root"

echo "=== [1/6] Зависимости ==="
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq; apt-get install -y -qq python3 python3-venv python3-pip curl nginx 2>/dev/null
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y -q python3 python3-pip curl nginx 2>/dev/null
fi

echo "=== [2/6] Скачивание бэкапов (2 архива по частям) ==="
cd /tmp
rm -f backup.part* opt.part* server_full_backup.tar.gz opt_and_nginx.tar.gz
for p in $(seq 1 7); do
  eval $CURL -o backup.part\${p}of7 "$REPO_RAW/backup.part\${p}of7"
  [ -s backup.part${p}of7 ] || { echo "FAIL: backup part $p"; exit 1; }
done
cat backup.part1of7 backup.part2of7 backup.part3of7 backup.part4of7 backup.part5of7 backup.part6of7 backup.part7of7 > server_full_backup.tar.gz
rm -f backup.part*
for p in $(seq 1 3); do
  eval $CURL -o opt.part\${p}of3 "$REPO_RAW/opt.part\${p}of3"
  [ -s opt.part${p}of3 ] || { echo "FAIL: opt part $p"; exit 1; }
done
cat opt.part1of3 opt.part2of3 opt.part3of3 > opt_and_nginx.tar.gz
rm -f opt.part*
echo "main: $(du -m server_full_backup.tar.gz | cut -f1) MB, opt: $(du -m opt_and_nginx.tar.gz | cut -f1) MB"

echo "=== [3/6] Распаковка проектов (33 проекта в /root) ==="
tar xzf server_full_backup.tar.gz -C /root

echo "=== [4/6] Распаковка сайтов (/opt), nginx, systemd (58 сервисов) ==="
tar xzf opt_and_nginx.tar.gz -C /
eval $CURL -o /tmp/systemd_units.tar.gz "$REPO_RAW/systemd_units.tar.gz"
mkdir -p /etc/systemd/system && tar xzf /tmp/systemd_units.tar.gz -C /etc/systemd/system
systemctl daemon-reload
nginx -t 2>/dev/null && systemctl enable --now nginx 2>/dev/null || true

echo "=== [5/6] Python venv ==="
mkdir -p /root/_shared_venvs
[ ! -d /root/_shared_venvs/bot-common ] && python3 -m venv /root/_shared_venvs/bot-common
[ ! -d /root/_shared_venvs/central-admin ] && python3 -m venv /root/_shared_venvs/central-admin
/root/_shared_venvs/bot-common/bin/pip install -q aiogram python-dotenv requests 2>/dev/null

echo "=== [6/6] Готово ==="
echo ""
echo "  33 проекта в /root, сайты в /opt, nginx + 58 systemd-сервисов"
echo "  Мульти-админка:  /root/central_admin"
echo "  Все грей-боты:   /root/gray_v2"
echo "  Запуск ботов:    systemctl start <name>"
echo "  Список:          systemctl list-unit-files | grep -E 'bot|admin'"
echo "  ВСЁ СРАЗУ:       for s in \$(systemctl list-unit-files --type=service | grep -iE 'bot|admin|shop|monitor|review|neon' | awk '{print \$1}'); do systemctl start \$s; done"

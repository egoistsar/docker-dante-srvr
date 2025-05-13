#!/bin/bash
set -e

LOGFILE="/var/log/cleanup.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "🧹 Начинаем полную очистку окружения ($(date))"

# 1. Удаление файлов и директорий
echo "🗑 Удаляю файлы проекта, конфиги, логи..."
rm -rf \
  /var/lib/docker \
  /etc/systemd/system/dante-docker.service \
  /etc/systemd/system/docker.service.d \
  /root/docker-dante-srvr \
  /root/config.env \
  /var/log/danted.log || true

# 2. Остановка и отключение сервисов
echo "🔻 Отключаю systemd-сервисы..."
systemctl disable dante-docker docker --now 2>/dev/null || true
systemctl daemon-reexec
systemctl reset-failed

# 3. Удаление установленных пакетов
echo "📦 Удаляю установленные пакеты..."
apt purge -y git docker.io sudo iptables net-tools || true
apt autoremove -y

echo "✅ Очистка завершена успешно"
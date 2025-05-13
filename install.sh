#!/bin/bash

set -e

echo "🌀 Установка Dante SOCKS5 через Docker с автозапуском"

# 1. Проверка root-доступа
if [[ $EUID -ne 0 ]]; then
  echo "❌ Этот скрипт должен запускаться от root"
  exit 1
fi

# 2. Установка зависимостей
echo "🔧 Проверка и установка зависимостей..."

apt update && apt install -y \
  curl \
  git \
  docker.io \
  sudo \
  iptables \
  systemd \
  systemd-sysv \
  net-tools

# 3. Включение Docker
systemctl enable docker
systemctl start docker

# 4. Клонирование репозитория
if [ ! -d "docker-dante-srvr" ]; then
  git clone https://github.com/egoistsar/docker-dante-srvr.git
fi
cd docker-dante-srvr

# 5. Ввод данных
read -p "🛠 Введите порт для прокси-сервера: " PORT
read -p "👤 Введите логин: " USERNAME
read -s -p "🔑 Введите пароль: " PASSWORD
echo

# 6. Сохранение параметров
cat <<EOF > config.env
PORT=$PORT
USERNAME=$USERNAME
PASSWORD=$PASSWORD
EOF

# 🔥 Firewall-проброс порта
echo "📡 Разрешаю входящий трафик на порт $PORT через iptables..."
iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT

# 7. Сборка образа
docker build -t dante-proxy .

# 8. Запуск контейнера
docker rm -f socks5 2>/dev/null || true
docker run -d --restart=always --network host --env-file=config.env --name socks5 dante-proxy

# 9. Установка systemd-сервиса
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

echo "✅ Установка завершена: Dante SOCKS5 запущен и автозапускается при ребуте."
echo "🔒 Логин: $USERNAME"
echo "🔑 Пароль: (скрыт)"
echo "📡 Порт: $PORT"
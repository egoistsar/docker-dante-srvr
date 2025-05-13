#!/bin/bash

set -e

echo "🌀 Установка Dante SOCKS5 через Docker с автозапуском и пробросом порта"

# 1. Проверка root-доступа
if [[ $EUID -ne 0 ]]; then
  echo "❌ Этот скрипт нужно запускать от root"
  exit 1
fi

# 2. Установка зависимостей
echo "🔧 Устанавливаю зависимости..."
apt update && apt install -y \
  curl \
  git \
  docker.io \
  sudo \
  iptables \
  systemd \
  systemd-sysv \
  net-tools

# 3. Включение и запуск Docker
systemctl enable docker
systemctl start docker

# 4. Клонирование проекта, если он ещё не клонирован
if [ ! -d "docker-dante-srvr" ]; then
  git clone https://github.com/egoistsar/docker-dante-srvr.git
fi
cd docker-dante-srvr

# 5. Ввод данных от пользователя
read -p "🛠 Введите порт для прокси-сервера: " PORT
read -p "👤 Введите логин: " USERNAME
read -s -p "🔑 Введите пароль: " PASSWORD
echo

# 6. Сохранение в файл config.env
cat <<EOF > config.env
PORT=$PORT
USERNAME=$USERNAME
PASSWORD=$PASSWORD
EOF

# 7. Firewall-проброс через iptables
echo "📡 Разрешаю входящие соединения на порт $PORT..."
iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT


# 8. Сборка Docker-образа
docker build -t dante-proxy .

# 9. Запуск контейнера с автоперезапуском
docker rm -f socks5 2>/dev/null || true
docker run -d --restart=always --network host --env-file=config.env --name socks5 dante-proxy

# 10. Установка systemd-сервиса
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

# 11. Финальный вывод
echo "✅ Установка завершена!"
echo "👂 Прокси работает на порту: $PORT"
echo "🔐 Логин: $USERNAME"
echo "📦 Контейнер: socks5"
echo "♻️ Автозапуск настроен через systemd"

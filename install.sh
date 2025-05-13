#!/bin/bash

set -e

echo "🌀 Установка Dante SOCKS5 через Docker"

# 1. Установка Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "🔧 Устанавливаю Docker..."
  apt update && apt install -y docker.io
fi

# 2. Клонирование репозитория
git clone https://github.com/egoistsar/docker-dante-srvr.git
cd docker-dante-srvr

# 3. Ввод переменных
read -p "🛠 Введите порт для прокси-сервера: " PORT
read -p "👤 Введите логин: " USERNAME
read -s -p "🔑 Введите пароль: " PASSWORD
echo

# 4. Сохранение в config.env
echo "PORT=$PORT" > config.env
echo "USERNAME=$USERNAME" >> config.env
echo "PASSWORD=$PASSWORD" >> config.env

# 5. Сборка и запуск
docker build -t dante-proxy .
docker run -d --restart=always --network host --env-file=config.env --name socks5 dante-proxy

# 6. Установка systemd-сервиса
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

echo "✅ Прокси-сервер запущен и будет автозапускаться при перезагрузке"
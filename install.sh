#!/bin/bash

set -e

echo "\U0001F300 Установка Dante SOCKS5 через Docker с автозапуском и пробросом порта"

# Проверка root-доступа
if [[ $EUID -ne 0 ]]; then
  echo "❌ Этот скрипт нужно запускать от root"
  exit 1
fi

# Установка зависимостей
DEPS=(curl git docker.io sudo iptables systemd systemd-sysv net-tools)
echo "\U0001F527 Проверка и установка зависимостей..."
for pkg in "${DEPS[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "📦 Устанавливаю: $pkg"
    apt update && apt install -y "$pkg"
  else
    echo "✅ $pkg уже установлен"
  fi
done

# Запуск Docker
systemctl enable docker
systemctl start docker

# Клонирование репозитория
if [ ! -d "docker-dante-srvr" ]; then
  git clone https://github.com/egoistsar/docker-dante-srvr.git
fi
cd docker-dante-srvr || exit 1

# Сбор данных от пользователя
read -t 60 -p "🛠 Введите порт для прокси-сервера: " PORT || { echo -e "\n⏰ Время вышло"; exit 1; }
read -t 60 -p "👤 Введите логин: " USERNAME || { echo -e "\n⏰ Время вышло"; exit 1; }
read -t 60 -s -p "🔑 Введите пароль: " PASSWORD || { echo -e "\n⏰ Время вышло"; exit 1; }
echo

# Сохранение в env-файл
cat <<EOF > config.env
PORT=$PORT
USERNAME=$USERNAME
PASSWORD=$PASSWORD
EOF

# Разрешение через iptables
iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT || echo "⚠️ Не удалось открыть порт через iptables. Проверьте вручную."

# Сборка образа
docker build -t dante-proxy-auto .

# Запуск контейнера
docker rm -f socks5 2>/dev/null || true
docker run -d --restart=always --network host --env-file=config.env --name socks5 dante-proxy-auto

# Установка systemd-сервиса
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

echo "\n✅ Установка завершена"
echo "🟢 Прокси доступен на порту: $PORT"
echo "Логин: $USERNAME"
echo "Пароль: $PASSWORD"
echo "Контейнер: socks5 (автозапуск через systemd)"
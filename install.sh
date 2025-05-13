#!/bin/bash

set -e

echo "🌀 Установка Dante SOCKS5 через Docker с автозапуском и пробросом порта"

# 1. Проверка root-доступа
if [[ $EUID -ne 0 ]]; then
  echo "❌ Этот скрипт нужно запускать от root"
  exit 1
fi

# 2. Проверка и установка зависимостей
echo "🔧 Проверка и установка зависимостей..."
DEPS=(curl git docker.io sudo iptables systemd systemd-sysv net-tools)
for pkg in "${DEPS[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "📦 Устанавливаю: $pkg"
    apt update && apt install -y "$pkg"
  else
    echo "✅ $pkg уже установлен"
  fi
done

# 3. Включение и запуск Docker
echo "🔄 Включаю Docker..."
systemctl enable docker
systemctl start docker

# 4. Клонирование проекта, если он ещё не клонирован
if [ ! -d "docker-dante-srvr" ]; then
  echo "⬇️ Клонирую репозиторий проекта..."
  git clone https://github.com/egoistsar/docker-dante-srvr.git
fi
cd docker-dante-srvr || { echo "❌ Не удалось перейти в папку проекта"; exit 1; }

# 5. Ввод данных от пользователя (с таймаутом 60 сек)
echo
read -t 60 -p "🛠 Введите порт для прокси-сервера (у вас 60 сек): " PORT || { echo -e "\n⏰ Время вышло"; exit 1; }
read -t 60 -p "👤 Введите логин (у вас 60 сек): " USERNAME || { echo -e "\n⏰ Время вышло"; exit 1; }
read -t 60 -s -p "🔑 Введите пароль (у вас 60 сек): " PASSWORD || { echo -e "\n⏰ Время вышло"; exit 1; }
echo

# 6. Сохранение в файл config.env
echo "💾 Сохраняю параметры в config.env..."
cat <<EOF > config.env
PORT=$PORT
USERNAME=$USERNAME
PASSWORD=$PASSWORD
EOF

# 7. Firewall-проброс через iptables
echo "📡 Разрешаю входящие соединения на порт $PORT через iptables..."
iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT || {
  echo "❌ Не удалось добавить правило в iptables"; exit 1;
}

# 8. Сборка Docker-образа
echo "🐳 Сборка Docker-образа..."
docker build -t dante-proxy .

# 9. Запуск контейнера с автоперезапуском
echo "🚀 Запуск контейнера socks5..."
docker rm -f socks5 2>/dev/null || true
docker run -d --restart=always --network host --env-file=config.env --name socks5 dante-proxy

# 10. Установка systemd-сервиса
echo "🛠 Устанавливаю systemd-сервис для автозапуска..."
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

# 11. Финальный вывод
echo
echo "✅ Установка завершена!"
echo "👂 Прокси работает на порту: $PORT"
echo "🔐 Логин: $USERNAME"
echo "📦 Контейнер: socks5"
echo "♻️ Автозапуск настроен через systemd"

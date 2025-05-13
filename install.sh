#!/bin/bash

set -e

# --- ПАРСИНГ АРГУМЕНТОВ ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --port)
      PORT="$2"
      shift 2
      ;;
    --user)
      USERNAME="$2"
      shift 2
      ;;
    --pass)
      PASSWORD="$2"
      shift 2
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    *)
      echo "❌ Неизвестный параметр: $1"
      exit 1
      ;;
  esac
done

# --- ПОДГРУЗКА .env ФАЙЛА ЕСЛИ УКАЗАН ---
if [[ -n "$ENV_FILE" ]]; then
  if [[ -f "$ENV_FILE" ]]; then
    echo "📄 Загружаю переменные из $ENV_FILE"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
  else
    echo "❌ Файл $ENV_FILE не найден"
    exit 1
  fi
fi

# --- ПРОВЕРКА ОБЯЗАТЕЛЬНЫХ ПЕРЕМЕННЫХ ---
: "${PORT:?❌ Не указана переменная --port}"
: "${USERNAME:?❌ Не указана переменная --user}"
: "${PASSWORD:?❌ Не указана переменная --pass}"

# --- ПРОВЕРКА ROOT ---
if [[ $EUID -ne 0 ]]; then
  echo "❌ Этот скрипт нужно запускать от root"
  exit 1
fi

# --- УСТАНОВКА ЗАВИСИМОСТЕЙ ---
DEPS=(curl git docker.io sudo iptables systemd systemd-sysv net-tools)
echo "🔧 Проверка и установка зависимостей..."
for pkg in "${DEPS[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "📦 Устанавливаю: $pkg"
    apt update && apt install -y "$pkg"
  else
    echo "✅ $pkg уже установлен"
  fi
done

# --- ЗАПУСК DOCKER ---
echo "🔄 Проверка и запуск Docker..."
systemctl enable docker
systemctl start docker
sleep 2

# --- ПРОВЕРКА ДОСТУПНОСТИ DOCKER ---
if ! docker info >/dev/null 2>&1; then
  echo "⚠️ Docker демон не запущен. Пробую перезапуск..."
  systemctl restart docker
  sleep 5
  if ! docker info >/dev/null 2>&1; then
    echo "🚫 Не удалось запустить Docker даже после перезапуска. Завершаем."
    exit 1
  fi
fi

# --- КЛОНИРОВАНИЕ РЕПОЗИТОРИЯ ---
if [ ! -d "docker-dante-srvr" ]; then
  git clone https://github.com/egoistsar/docker-dante-srvr.git
fi
cd docker-dante-srvr || exit 1

# --- СОХРАНЕНИЕ config.env ---
echo "💾 Создаю config.env..."
cat <<EOF > config.env
PORT=$PORT
USERNAME=$USERNAME
PASSWORD=$PASSWORD
EOF

# --- IPTABLES ---
echo "📡 Проброс порта через iptables: $PORT"
iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT || {
  echo "⚠️ Не удалось открыть порт. Возможно, iptables отключен или уже добавлено правило."
}

# --- ЕЩЁ РАЗ ПРОВЕРКА DOCKER ПЕРЕД СБОРКОЙ ---
echo "🔍 Проверка docker.sock перед сборкой..."
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker демон снова не запущен. Пробуем ещё раз..."
  systemctl restart docker
  sleep 5
  if ! docker info >/dev/null 2>&1; then
    echo "🚫 Не удалось запустить Docker. Завершаем."
    exit 1
  fi
fi

# --- СБОРКА ---
echo "🐳 Сборка Docker-образа..."
docker build -t dante-proxy-auto .

# --- ЗАПУСК ---
echo "🚀 Запуск контейнера socks5..."
docker rm -f socks5 2>/dev/null || true
docker run -d --restart=always --network host --env-file=config.env --name socks5 dante-proxy-auto

# --- SYSTEMD ---
echo "🛠 Установка systemd-сервиса..."
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

# --- ГОТОВО ---
echo -e "\n✅ Установка завершена"
echo "🟢 Прокси работает на порту: $PORT"
echo "🔐 Логин: $USERNAME"
echo "📦 Контейнер: socks5"

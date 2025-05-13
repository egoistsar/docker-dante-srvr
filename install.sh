#!/bin/bash

set -e

# --- ПАРСИНГ АРГУМЕНТОВ ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --port) PORT="$2"; shift 2 ;;
    --user) USERNAME="$2"; shift 2 ;;
    --pass) PASSWORD="$2"; shift 2 ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    *) echo "❌ Неизвестный параметр: $1"; exit 1 ;;
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
DEPS=(curl git docker.io sudo iptables systemd systemd-sysv net-tools apparmor-utils apparmor)
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
    echo "🚫 Не удалось запустить Docker. Переустанавливаю..."
    apt purge -y docker.io containerd runc
    apt update && apt install -y docker.io
    systemctl restart docker
    sleep 5
    if ! docker info >/dev/null 2>&1; then
      echo "❌ Docker всё ещё не запускается. Вот журнал ошибок:"
      journalctl -u docker --no-pager | tail -n 30
      exit 1
    fi
  fi
fi

# --- ДОП. ИНФОРМАЦИЯ ---
echo "🧩 Версия Docker: $(docker --version)"
echo "🌐 IP интерфейс VPS: $(hostname -I | awk '{print $1}')"

# --- КЛОНИРОВАНИЕ РЕПОЗИТОРИЯ ---
if [ ! -d "docker-dante-srvr" ]; then
  git clone https://github.com/egoistsar/docker-dante-srvr.git
fi
cd docker-dante-srvr || exit 1

# --- ПРОВЕРКА: обновлён ли Dockerfile ---
echo "🔍 Проверка Dockerfile на наличие iproute2..."
if ! grep -q "iproute2" Dockerfile; then
  echo "⚠️ ВНИМАНИЕ: В Dockerfile отсутствует iproute2. Добавь его в RUN apt-get install"
  echo "   Пример: apt-get install -y dante-server iproute2 gettext-base"
  exit 1
fi

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

# --- СБОРКА ---
echo "🐳 Собираю Docker-образ..."
DOCKER_BUILD_LOG=$(mktemp)
docker build --no-cache -t dante-proxy-auto . >"$DOCKER_BUILD_LOG" 2>&1 || BUILD_FAILED=1

# if grep -q "apparmor_parser" "$DOCKER_BUILD_LOG"; then
 # echo "⚠️ AppArmor включён, но apparmor_parser не найден. Проблема проигнорирована."
# fi

if [[ "$BUILD_FAILED" == "1" ]] && ! docker image inspect dante-proxy-auto >/dev/null 2>&1; then
  echo "❌ Ошибка при сборке Docker-образа:"
  cat "$DOCKER_BUILD_LOG"
  rm "$DOCKER_BUILD_LOG"
  exit 1
fi

rm "$DOCKER_BUILD_LOG"

# --- ЗАПУСК ---
docker rm -f socks5 2>/dev/null || true
docker run -d \
  --restart=always \
  --network host \
  --env-file=config.env \
  --security-opt apparmor=unconfined \
  --name socks5 \
  dante-proxy-auto

# --- SYSTEMD ---
echo "🛠 Установка systemd-сервиса..."
cp dante-docker.service /etc/systemd/system/
systemctl daemon-reexec
systemctl enable dante-docker
systemctl start dante-docker

# --- ФИНАЛЬНАЯ ПРОВЕРКА ---
echo -e "\n📋 Проверка состояния SOCKS5-сервера..."
echo "--------------------------------------"
echo "🔎 Контейнер socks5:"
docker ps -f name=socks5 --format "   ▸ {{.Status}}"
echo

echo "📡 Проверка слушания порта $PORT:"
if ss -tnlp | grep -q ":$PORT"; then
  echo "   ✅ Порт $PORT слушается"
else
  echo "   ❌ Порт $PORT не слушается"
fi
echo

echo "📄 Последние строки из логов socks5:"
docker logs --tail 10 socks5 | sed 's/^/   /'
echo "--------------------------------------"
SERVER_IP=$(hostname -I | awk '{print $1}')
# Финальный вывод:
echo -e "\n✅ Установка завершена"
echo "🌍 IP сервера: $SERVER_IP"
echo "🟢 Прокси работает на порту: $PORT"
echo "🔐 Логин: $USERNAME"
echo "🔐 Логин: $PASSWORD"
echo "📦 Контейнер: socks5"
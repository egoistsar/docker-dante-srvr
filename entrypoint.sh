#!/bin/bash
set -e

# 1. Проверка и определение сетевого интерфейса
if ! command -v ip >/dev/null 2>&1; then
  echo "❌ Команда 'ip' не найдена. Убедитесь, что установлен iproute2."
  exit 1
fi

NET_IFACE=$(ip route get 1 | awk '{print $5; exit}')
echo "🌐 Используем сетевой интерфейс: $NET_IFACE"

# 2. Подстановка переменных окружения в шаблон конфигурации
export PORT USERNAME PASSWORD NET_IFACE
envsubst < /etc/danted.conf.template > /etc/danted.conf

# 3. Создание пользователя (если не существует)
if ! id "$USERNAME" &>/dev/null; then
  useradd -M "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd
else
  echo "⚠️ Пользователь '$USERNAME' уже существует, пропускаем создание"
fi

# 4. Запуск danted
echo "🚀 Запускаем Dante SOCKS5-прокси на порту $PORT"
exec danted -f /etc/danted.conf

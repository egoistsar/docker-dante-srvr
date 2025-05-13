#!/bin/bash
set -e

# 1. Проверка и установка iproute2 при необходимости
if ! command -v ip >/dev/null 2>&1; then
  echo "⚠️ Команда 'ip' не найдена. Пробуем установить iproute2..."
  apt-get update && apt-get install -y iproute2 >/dev/null
  if ! command -v ip >/dev/null 2>&1; then
    echo "❌ Не удалось установить 'iproute2'. Завершение."
    exit 1
  fi
fi

# 2. Получение сетевого интерфейса
NET_IFACE=$(ip route get 1 | awk '{print $5; exit}')
echo "🌐 Используем сетевой интерфейс: $NET_IFACE"

# 3. Подстановка переменных окружения в шаблон
export PORT USERNAME PASSWORD NET_IFACE
envsubst < /etc/danted.conf.template > /etc/danted.conf

# 4. Проверка подстановки переменных
if grep -q '\${' /etc/danted.conf; then
  echo "❌ В конфигурации остались неподставленные переменные. Прерываем запуск."
  echo "⚠️ Содержимое danted.conf:"
  cat /etc/danted.conf
  exit 1
fi

# 5. Создание пользователя (если не существует)
if ! id "$USERNAME" &>/dev/null; then
  useradd -M "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd
else
  echo "⚠️ Пользователь '$USERNAME' уже существует, пропускаем создание"
fi

# 6. Запуск danted
echo "🚀 Запускаем Dante SOCKS5-прокси на порту $PORT"
exec danted -f /etc/danted.conf

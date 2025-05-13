#!/bin/bash
set -e

if ! command -v ip >/dev/null 2>&1; then
  echo "⚠️ Команда 'ip' не найдена. Пробуем установить iproute2..."
  apt-get update && apt-get install -y iproute2 >/dev/null
  if ! command -v ip >/dev/null 2>&1; then
    echo "❌ Не удалось установить 'iproute2'. Завершение."
    exit 1
  fi
fi

NET_IFACE=$(ip route get 1 | awk '{print $5; exit}')
echo "🌐 Используем сетевой интерфейс: $NET_IFACE"

export PORT USERNAME PASSWORD NET_IFACE
envsubst < /etc/danted.conf.template > /etc/danted.conf

if grep -q '\${' /etc/danted.conf; then
  echo "❌ В конфигурации остались неподставленные переменные. Прерываем запуск."
  cat /etc/danted.conf
  exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
  useradd -M "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd
else
  echo "⚠️ Пользователь '$USERNAME' уже существует, пропускаем создание"
fi

exec danted -f /etc/danted.conf
#!/bin/bash
set -e

NET_IFACE=$(ip route get 1 | awk '{print $5; exit}')
echo "🌐 Используем сетевой интерфейс: $NET_IFACE"

export NET_IFACE
export PORT=${PORT:-1080}
export USERNAME=${USERNAME:-user}
export PASSWORD=${PASSWORD:-pass}

# Генерация конфигурации
envsubst < /etc/danted.conf.template > /etc/danted.conf

# Добавление пользователя
useradd -M -s /usr/sbin/nologin "$USERNAME" || true
echo "$USERNAME:$PASSWORD" | chpasswd

# Запуск
exec danted -f /etc/danted.conf
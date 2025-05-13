#!/bin/bash

# Получение значений из ENV
PORT=${PORT:-1080}
USERNAME=${USERNAME:-proxy}
PASSWORD=${PASSWORD:-123456}

echo "🔧 Запуск Dante SOCKS5 на порту $PORT для пользователя $USERNAME"

useradd -m "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

envsubst < /etc/danted.conf.template > /etc/danted.conf
exec danted -f /etc/danted.conf
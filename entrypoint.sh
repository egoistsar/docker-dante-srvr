#!/bin/bash

echo "🔧 Настройка SOCKS5 прокси-сервера Dante"

read -p "🛠 Введите порт для сервера: " PORT
read -p "👤 Введите имя пользователя: " USERNAME
read -s -p "🔑 Введите пароль: " PASSWORD
echo

# Создание системного пользователя
useradd -m "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Генерация конфига
export PORT
envsubst < /etc/danted.conf.template > /etc/danted.conf

echo "✅ Конфиг создан. Запуск Dante..."

exec danted -f /etc/danted.conf
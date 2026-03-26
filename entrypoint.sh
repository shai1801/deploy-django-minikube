#!/bin/sh
set -e

echo "Waiting for database..."
until python manage.py inspectdb > /dev/null 2>&1; do
  echo "Database not ready — retrying in 2s..."
  sleep 2
done

echo "Running migrations..."
python manage.py migrate --noinput

echo "Starting Gunicorn..."
exec gunicorn mysite.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --timeout 120

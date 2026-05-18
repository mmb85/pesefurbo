#!/bin/bash
set -e

# Remove stale pidfile
rm -f /app/tmp/pids/server.pid

# Wait for PostgreSQL to be ready
until pg_isready -h db -p 5432; do
  echo 'Waiting for PostgreSQL...'
  sleep 1
done

# Run pending migrations
bundle exec rake db:migrate

# Execute the command passed as arguments
exec "$@"

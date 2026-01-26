#!/bin/bash
set -e

echo "Waiting for Postgres to be ready..."
until pg_isready -h "${PGUSER:-postgres}"; do
  sleep 1
done

echo "Configuring Postgres for Supabase Realtime..."

# Apply configuration changes
psql "$DATABASE_URL" <<-EOSQL
    -- Grant necessary privileges
    GRANT ALL PRIVILEGES ON DATABASE $PGDATABASE TO $PGUSER;

    -- Enable replication role
    ALTER ROLE $PGUSER WITH REPLICATION;

    -- Drop publication if exists (for idempotency)
    DROP PUBLICATION IF EXISTS supabase_realtime;

    -- Create publication for realtime
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;

    -- Verify settings
    SELECT 'WAL Level: ' || setting FROM pg_settings WHERE name = 'wal_level';
    SELECT 'Max Replication Slots: ' || setting FROM pg_settings WHERE name = 'max_replication_slots';
    SELECT 'Max WAL Senders: ' || setting FROM pg_settings WHERE name = 'max_wal_senders';
EOSQL

echo "Realtime configuration complete!"

# Database Migrations

This directory contains SQL migration files for the Map App PostgreSQL database.

## Prerequisites

- PostgreSQL 12 or higher
- PostGIS extension enabled
- Database created (default: `map_app`)

## Running Migrations

### Initial Setup

1. Create the database:
```bash
psql -U postgres -c "CREATE DATABASE map_app;"
```

2. Apply the base schema:
```bash
psql -U postgres -d map_app -f schema.sql
```

3. Apply migration 001 (align schema with backend API):
```bash
psql -U postgres -d map_app -f migration_001_align_schema.sql
```

4. Apply migration 002 (fix users ID generation):
```bash
psql -U postgres -d map_app -f migration_002_fix_users_id_generation.sql
```

### Migration Order

**IMPORTANT:** Migrations must be applied in order:

1. `schema.sql` - Base schema
2. `migration_001_align_schema.sql` - Align with backend API
3. `migration_002_fix_users_id_generation.sql` - Fix ID generation issue

## Migration 002: Fix Users ID Generation

This migration fixes the critical issue where the `users` table ID column was not auto-generating values, causing the error:

```
null value in column "id" of relation "users" violates not-null constraint
```

### What it does:

1. Changes `users.id` from `VARCHAR(255)` to `UUID` with auto-generation using `uuid_generate_v4()`
2. Updates all foreign key references to use UUID
3. Recreates all foreign key constraints
4. Updates all stored functions that reference user IDs
5. Recreates all views with the correct UUID type

### Data Safety:

- Existing user IDs are preserved if they are valid UUIDs
- Invalid IDs are replaced with newly generated UUIDs
- All relationships (polygons, points, projects) are maintained

## Troubleshooting

### Issue: "uuid-ossp extension does not exist"

```bash
psql -U postgres -d map_app -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
```

### Issue: "postgis extension does not exist"

```bash
psql -U postgres -d map_app -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

### Check current schema version

```bash
psql -U postgres -d map_app -c "\d users"
```

You should see `id | uuid | not null default uuid_generate_v4()`

## Environment Setup

Make sure your `.env` file in the backend directory has the correct database credentials:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=map_app
DB_USER=postgres
DB_PASSWORD=your_password
```

## Rollback

If you need to rollback migration 002, you'll need to:

1. Backup your data first
2. Manually convert UUID columns back to VARCHAR
3. Update foreign keys accordingly

**Note:** It's recommended to test migrations in a development environment before applying to production.

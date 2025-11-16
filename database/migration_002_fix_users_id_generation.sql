-- Migration: Fix users table ID generation
-- Problem: The users.id column is VARCHAR without default value,
-- causing "null value in column 'id' violates not-null constraint" errors
-- Solution: Change to UUID with auto-generation

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 1: Add a temporary UUID column
ALTER TABLE users ADD COLUMN IF NOT EXISTS id_new UUID DEFAULT uuid_generate_v4();

-- Step 2: Update existing records with UUIDs (if any exist)
-- For existing records with VARCHAR IDs, we'll keep them as-is if they're valid UUIDs
-- Otherwise generate new UUIDs
DO $$
BEGIN
    -- Try to cast existing IDs to UUID, generate new ones if cast fails
    UPDATE users
    SET id_new =
        CASE
            WHEN id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN id::UUID
            ELSE uuid_generate_v4()
        END
    WHERE id_new IS NULL;
END $$;

-- Step 3: Drop foreign key constraints that reference users.id
ALTER TABLE polygones DROP CONSTRAINT IF EXISTS polygones_user_id_fkey;
ALTER TABLE points DROP CONSTRAINT IF EXISTS points_user_id_fkey;
ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_created_by_fkey;
ALTER TABLE project_contributors DROP CONSTRAINT IF EXISTS project_contributors_user_id_fkey;

-- Step 4: Update foreign key columns to UUID type
-- Add temporary columns
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS user_id_new UUID;
ALTER TABLE points ADD COLUMN IF NOT EXISTS user_id_new UUID;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS created_by_new UUID;
ALTER TABLE project_contributors ADD COLUMN IF NOT EXISTS user_id_new UUID;

-- Copy data from old to new columns, matching by the user's ID
UPDATE polygones p SET user_id_new = u.id_new FROM users u WHERE p.user_id = u.id;
UPDATE points pt SET user_id_new = u.id_new FROM users u WHERE pt.user_id = u.id;
UPDATE projects pr SET created_by_new = u.id_new FROM users u WHERE pr.created_by = u.id;
UPDATE project_contributors pc SET user_id_new = u.id_new FROM users u WHERE pc.user_id = u.id;

-- Step 5: Drop old columns and rename new ones
ALTER TABLE users DROP COLUMN IF EXISTS id CASCADE;
ALTER TABLE users RENAME COLUMN id_new TO id;

ALTER TABLE polygones DROP COLUMN IF EXISTS user_id;
ALTER TABLE polygones RENAME COLUMN user_id_new TO user_id;

ALTER TABLE points DROP COLUMN IF EXISTS user_id;
ALTER TABLE points RENAME COLUMN user_id_new TO user_id;

ALTER TABLE projects DROP COLUMN IF EXISTS created_by;
ALTER TABLE projects RENAME COLUMN created_by_new TO created_by;

ALTER TABLE project_contributors DROP COLUMN IF EXISTS user_id;
ALTER TABLE project_contributors RENAME COLUMN user_id_new TO user_id;

-- Step 6: Add primary key and constraints back
ALTER TABLE users ADD PRIMARY KEY (id);
ALTER TABLE users ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- Step 7: Make foreign key columns NOT NULL where appropriate and add foreign key constraints
ALTER TABLE polygones ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE polygones ADD CONSTRAINT polygones_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE points ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE points ADD CONSTRAINT points_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE projects ALTER COLUMN created_by SET NOT NULL;
ALTER TABLE projects ADD CONSTRAINT projects_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE project_contributors ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE project_contributors ADD CONSTRAINT project_contributors_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 8: Recreate indexes on users.id
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Step 9: Recreate indexes on foreign key columns
CREATE INDEX IF NOT EXISTS idx_polygones_user_id ON polygones(user_id);
CREATE INDEX IF NOT EXISTS idx_points_user_id ON points(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by);
CREATE INDEX IF NOT EXISTS idx_project_contributors_user ON project_contributors(user_id);

-- Step 10: Update function signatures that use user_id
DROP FUNCTION IF EXISTS increment_contribution_count(VARCHAR);
CREATE OR REPLACE FUNCTION increment_contribution_count(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE users
    SET contribution_count = contribution_count + 1
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS add_user_to_project(INTEGER, VARCHAR);
CREATE OR REPLACE FUNCTION add_user_to_project(
    p_project_id INTEGER,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO project_contributors (project_id, user_id)
    VALUES (p_project_id, p_user_id)
    ON CONFLICT (project_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS remove_user_from_project(INTEGER, VARCHAR);
CREATE OR REPLACE FUNCTION remove_user_from_project(
    p_project_id INTEGER,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM project_contributors
    WHERE project_id = p_project_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS user_has_project_access(INTEGER, VARCHAR);
CREATE OR REPLACE FUNCTION user_has_project_access(
    p_project_id INTEGER,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    user_role VARCHAR;
    is_contributor BOOLEAN;
    is_creator BOOLEAN;
BEGIN
    -- Get user role
    SELECT role INTO user_role FROM users WHERE id = p_user_id;

    -- Admins have access to all projects
    IF user_role = 'admin' THEN
        RETURN TRUE;
    END IF;

    -- Check if user is the creator
    SELECT EXISTS (
        SELECT 1 FROM projects WHERE id = p_project_id AND created_by = p_user_id
    ) INTO is_creator;

    IF is_creator THEN
        RETURN TRUE;
    END IF;

    -- Check if user is a contributor
    SELECT EXISTS (
        SELECT 1 FROM project_contributors WHERE project_id = p_project_id AND user_id = p_user_id
    ) INTO is_contributor;

    RETURN is_contributor;
END;
$$ LANGUAGE plpgsql;

-- Step 11: Update views that reference user columns
DROP VIEW IF EXISTS user_stats CASCADE;
DROP VIEW IF EXISTS adopted_polygones CASCADE;
DROP VIEW IF EXISTS adopted_points CASCADE;
DROP VIEW IF EXISTS project_stats CASCADE;

-- Recreate user_stats view
CREATE OR REPLACE VIEW user_stats AS
SELECT
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.role,
    u.points_contributed,
    u.polygones_contributed,
    u.contribution_count,
    COUNT(DISTINCT p.id) as polygon_count,
    COUNT(DISTINCT pt.id) as point_count,
    u.created_at,
    u.last_login
FROM users u
LEFT JOIN polygones p ON u.id = p.user_id
LEFT JOIN points pt ON u.id = pt.user_id
GROUP BY u.id, u.email, u.first_name, u.last_name, u.role, u.points_contributed,
         u.polygones_contributed, u.contribution_count, u.created_at, u.last_login;

-- Recreate adopted_polygones view
CREATE OR REPLACE VIEW adopted_polygones AS
SELECT
    p.*,
    u.email as user_email,
    ST_AsGeoJSON(p.geometry) as geometry_geojson
FROM polygones p
JOIN users u ON p.user_id = u.id
WHERE p.is_adopted = TRUE;

-- Recreate adopted_points view
CREATE OR REPLACE VIEW adopted_points AS
SELECT
    pt.*,
    u.email as user_email,
    ST_AsGeoJSON(pt.geometry) as geometry_geojson
FROM points pt
JOIN users u ON pt.user_id = u.id
WHERE pt.is_adopted = TRUE;

-- Recreate project_stats view
CREATE OR REPLACE VIEW project_stats AS
SELECT
    p.id,
    p.name,
    p.description,
    p.project_type,
    p.status,
    p.target_area,
    p.start_date,
    p.end_date,
    u.email as creator_email,
    u.first_name as creator_first_name,
    u.last_name as creator_last_name,
    COUNT(DISTINCT pc.user_id) as contributor_count,
    COUNT(DISTINCT poly.id) as polygon_count,
    COUNT(DISTINCT pt.id) as point_count,
    COUNT(DISTINCT poly.id) + COUNT(DISTINCT pt.id) as total_features,
    p.created_at,
    p.updated_at
FROM projects p
JOIN users u ON p.created_by = u.id
LEFT JOIN project_contributors pc ON p.id = pc.project_id
LEFT JOIN polygones poly ON p.id = poly.project_id
LEFT JOIN points pt ON p.id = pt.project_id
GROUP BY p.id, p.name, p.description, p.project_type, p.status, p.target_area,
         p.start_date, p.end_date, u.email, u.first_name, u.last_name, p.created_at, p.updated_at;

-- Update stored functions that return user_id
DROP FUNCTION IF EXISTS get_polygones_in_bbox(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, VARCHAR, BOOLEAN);
CREATE OR REPLACE FUNCTION get_polygones_in_bbox(
    min_lng DOUBLE PRECISION,
    min_lat DOUBLE PRECISION,
    max_lng DOUBLE PRECISION,
    max_lat DOUBLE PRECISION,
    p_type VARCHAR DEFAULT NULL,
    p_is_adopted BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    id INTEGER,
    district VARCHAR,
    gouvernante VARCHAR,
    type VARCHAR,
    geometry_geojson TEXT,
    message TEXT,
    image_url TEXT,
    user_id UUID,
    is_adopted BOOLEAN,
    date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.district,
        p.gouvernante,
        p.type,
        ST_AsGeoJSON(p.geometry)::TEXT,
        p.message,
        p.image_url,
        p.user_id,
        p.is_adopted,
        p.date
    FROM polygones p
    WHERE
        ST_Intersects(
            p.geometry,
            ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)
        )
        AND (p_type IS NULL OR p.type = p_type)
        AND p.is_adopted = p_is_adopted;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_points_in_bbox(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, VARCHAR, BOOLEAN);
CREATE OR REPLACE FUNCTION get_points_in_bbox(
    min_lng DOUBLE PRECISION,
    min_lat DOUBLE PRECISION,
    max_lng DOUBLE PRECISION,
    max_lat DOUBLE PRECISION,
    p_type VARCHAR DEFAULT NULL,
    p_is_adopted BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    id INTEGER,
    district VARCHAR,
    gouvernante VARCHAR,
    type VARCHAR,
    geometry_geojson TEXT,
    message TEXT,
    image_url TEXT,
    user_id UUID,
    is_adopted BOOLEAN,
    date TIMESTAMP WITH TIME ZONE,
    parcel_size VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pt.id,
        pt.district,
        pt.gouvernante,
        pt.type,
        ST_AsGeoJSON(pt.geometry)::TEXT,
        pt.message,
        pt.image_url,
        pt.user_id,
        pt.is_adopted,
        pt.date,
        pt.parcel_size
    FROM points pt
    WHERE
        ST_Within(
            pt.geometry,
            ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)
        )
        AND (p_type IS NULL OR pt.type = p_type)
        AND pt.is_adopted = p_is_adopted;
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON COLUMN users.id IS 'Auto-generated UUID primary key';

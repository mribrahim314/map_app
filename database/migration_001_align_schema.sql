-- Migration: Align database schema with backend API
-- This migration adds missing columns and updates existing ones

-- ============================================
-- 1. UPDATE USERS TABLE
-- ============================================

-- Add missing columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS points_contributed INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS polygones_contributed INTEGER DEFAULT 0;

-- Update role values to match API (normal -> user)
UPDATE users SET role = 'user' WHERE role = 'normal';

-- Update role constraint to new values
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'admin', 'moderator'));

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_users_first_name ON users(first_name);
CREATE INDEX IF NOT EXISTS idx_users_last_name ON users(last_name);

-- ============================================
-- 2. UPDATE POLYGONES TABLE
-- ============================================

-- Add missing columns to polygones table
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS crop_type VARCHAR(255);
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS area DOUBLE PRECISION;
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS perimeter DOUBLE PRECISION;
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

-- Copy existing data to new columns
UPDATE polygones SET crop_type = type WHERE crop_type IS NULL;
UPDATE polygones SET notes = message WHERE notes IS NULL;
UPDATE polygones SET images = jsonb_build_array(image_url) WHERE image_url IS NOT NULL AND images = '[]'::jsonb;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_polygones_crop_type ON polygones(crop_type);
CREATE INDEX IF NOT EXISTS idx_polygones_area ON polygones(area);

-- ============================================
-- 3. UPDATE POINTS TABLE
-- ============================================

-- Add missing columns to points table
ALTER TABLE points ADD COLUMN IF NOT EXISTS crop_type VARCHAR(255);
ALTER TABLE points ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE points ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

-- Copy existing data to new columns
UPDATE points SET crop_type = type WHERE crop_type IS NULL;
UPDATE points SET notes = message WHERE notes IS NULL;
UPDATE points SET images = jsonb_build_array(image_url) WHERE image_url IS NOT NULL AND images = '[]'::jsonb;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_points_crop_type ON points(crop_type);

-- ============================================
-- 4. UPDATE PROJECTS TABLE
-- ============================================

-- Add missing columns to projects table
ALTER TABLE projects ADD COLUMN IF NOT EXISTS target_area DOUBLE PRECISION;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

-- Update status constraint
ALTER TABLE projects ADD CONSTRAINT projects_status_check CHECK (status IN ('active', 'completed', 'cancelled'));

-- Copy is_active to status
UPDATE projects SET status = CASE
    WHEN is_active = TRUE THEN 'active'
    ELSE 'cancelled'
END;

-- Create index for status
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);

-- ============================================
-- 5. UPDATE PROJECT_CONTRIBUTORS TABLE
-- ============================================

-- Rename added_at to joined_at for consistency
ALTER TABLE project_contributors RENAME COLUMN added_at TO joined_at;

-- ============================================
-- 6. ADD HELPFUL VIEWS
-- ============================================

-- Drop old views if they exist
DROP VIEW IF EXISTS user_stats CASCADE;
DROP VIEW IF EXISTS project_stats CASCADE;

-- Recreated user_stats view with new columns
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

-- Recreated project_stats view with new columns
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

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN users.first_name IS 'User first name';
COMMENT ON COLUMN users.last_name IS 'User last name';
COMMENT ON COLUMN users.last_login IS 'Timestamp of last successful login';
COMMENT ON COLUMN users.points_contributed IS 'Total number of points contributed by user';
COMMENT ON COLUMN users.polygones_contributed IS 'Total number of polygons contributed by user';

COMMENT ON COLUMN polygones.crop_type IS 'Type of crop (replaces type column)';
COMMENT ON COLUMN polygones.area IS 'Area in square meters';
COMMENT ON COLUMN polygones.perimeter IS 'Perimeter in meters';
COMMENT ON COLUMN polygones.notes IS 'Additional notes (replaces message column)';
COMMENT ON COLUMN polygones.images IS 'Array of image URLs stored as JSONB';

COMMENT ON COLUMN points.crop_type IS 'Type of crop (replaces type column)';
COMMENT ON COLUMN points.notes IS 'Additional notes (replaces message column)';
COMMENT ON COLUMN points.images IS 'Array of image URLs stored as JSONB';

COMMENT ON COLUMN projects.target_area IS 'Target area to be covered in square meters';
COMMENT ON COLUMN projects.status IS 'Project status: active, completed, or cancelled';

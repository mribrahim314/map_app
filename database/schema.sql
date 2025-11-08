-- PostgreSQL/PostGIS Schema for Agricultural Mapping App
-- Migration from Firebase Firestore to PostgreSQL with PostGIS extension

-- Enable PostGIS extension for geospatial support
CREATE EXTENSION IF NOT EXISTS postgis;

-- Users table (migrated from Firebase 'users' collection)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,  -- Firebase Auth UID or new UUID
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),  -- For local auth (if migrating away from Firebase Auth)
    role VARCHAR(50) DEFAULT 'normal' CHECK (role IN ('normal', 'admin', 'moderator')),
    contribution_count INTEGER DEFAULT 0,
    contribution_request_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Polygones table (migrated from Firebase 'polygones' collection)
CREATE TABLE IF NOT EXISTS polygones (
    id SERIAL PRIMARY KEY,
    district VARCHAR(255) NOT NULL,
    gouvernante VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    geometry GEOMETRY(POLYGON, 4326) NOT NULL,  -- PostGIS geometry column (SRID 4326 = WGS84)
    message TEXT,
    image_url TEXT,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_adopted BOOLEAN DEFAULT FALSE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial index for efficient geospatial queries
CREATE INDEX IF NOT EXISTS idx_polygones_geometry ON polygones USING GIST(geometry);
CREATE INDEX IF NOT EXISTS idx_polygones_user_id ON polygones(user_id);
CREATE INDEX IF NOT EXISTS idx_polygones_type ON polygones(type);
CREATE INDEX IF NOT EXISTS idx_polygones_is_adopted ON polygones(is_adopted);
CREATE INDEX IF NOT EXISTS idx_polygones_district ON polygones(district);
CREATE INDEX IF NOT EXISTS idx_polygones_gouvernante ON polygones(gouvernante);

-- Points table (migrated from Firebase 'points' collection)
CREATE TABLE IF NOT EXISTS points (
    id SERIAL PRIMARY KEY,
    district VARCHAR(255) NOT NULL,
    gouvernante VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    geometry GEOMETRY(POINT, 4326) NOT NULL,  -- PostGIS geometry column
    message TEXT,
    image_url TEXT,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_adopted BOOLEAN DEFAULT FALSE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    parcel_size VARCHAR(50) CHECK (parcel_size IN ('Small', 'Medium', 'Large')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial index for efficient geospatial queries
CREATE INDEX IF NOT EXISTS idx_points_geometry ON points USING GIST(geometry);
CREATE INDEX IF NOT EXISTS idx_points_user_id ON points(user_id);
CREATE INDEX IF NOT EXISTS idx_points_type ON points(type);
CREATE INDEX IF NOT EXISTS idx_points_is_adopted ON points(is_adopted);
CREATE INDEX IF NOT EXISTS idx_points_district ON points(district);
CREATE INDEX IF NOT EXISTS idx_points_gouvernante ON points(gouvernante);
CREATE INDEX IF NOT EXISTS idx_points_parcel_size ON points(parcel_size);

-- Trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_polygones_updated_at
    BEFORE UPDATE ON polygones
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_points_updated_at
    BEFORE UPDATE ON points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to increment user contribution count
CREATE OR REPLACE FUNCTION increment_contribution_count(p_user_id VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE users
    SET contribution_count = contribution_count + 1
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- View for user statistics
CREATE OR REPLACE VIEW user_stats AS
SELECT
    u.id,
    u.email,
    u.role,
    u.contribution_count,
    COUNT(DISTINCT p.id) as polygon_count,
    COUNT(DISTINCT pt.id) as point_count
FROM users u
LEFT JOIN polygones p ON u.id = p.user_id
LEFT JOIN points pt ON u.id = pt.user_id
GROUP BY u.id, u.email, u.role, u.contribution_count;

-- View for adopted (published) polygones with user info
CREATE OR REPLACE VIEW adopted_polygones AS
SELECT
    p.*,
    u.email as user_email,
    ST_AsGeoJSON(p.geometry) as geometry_geojson
FROM polygones p
JOIN users u ON p.user_id = u.id
WHERE p.is_adopted = TRUE;

-- View for adopted (published) points with user info
CREATE OR REPLACE VIEW adopted_points AS
SELECT
    pt.*,
    u.email as user_email,
    ST_AsGeoJSON(pt.geometry) as geometry_geojson
FROM points pt
JOIN users u ON pt.user_id = u.id
WHERE pt.is_adopted = TRUE;

-- Function to get polygones by bounding box (useful for map viewport queries)
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
    user_id VARCHAR,
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

-- Function to get points by bounding box
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
    user_id VARCHAR,
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

-- Projects table for organizing data collection campaigns
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    project_type VARCHAR(100) NOT NULL, -- e.g., 'fruit_trees', 'solar_panels', 'irrigation', etc.
    created_by VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for projects table
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON projects(created_by);
CREATE INDEX IF NOT EXISTS idx_projects_type ON projects(project_type);
CREATE INDEX IF NOT EXISTS idx_projects_is_active ON projects(is_active);

-- Apply trigger to projects table
CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Project Contributors table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS project_contributors (
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, user_id)
);

-- Create indexes for project_contributors table
CREATE INDEX IF NOT EXISTS idx_project_contributors_project ON project_contributors(project_id);
CREATE INDEX IF NOT EXISTS idx_project_contributors_user ON project_contributors(user_id);

-- Add project_id to polygones table
ALTER TABLE polygones ADD COLUMN IF NOT EXISTS project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_polygones_project_id ON polygones(project_id);

-- Add project_id to points table
ALTER TABLE points ADD COLUMN IF NOT EXISTS project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_points_project_id ON points(project_id);

-- View for project statistics
CREATE OR REPLACE VIEW project_stats AS
SELECT
    p.id,
    p.name,
    p.description,
    p.project_type,
    p.is_active,
    p.start_date,
    p.end_date,
    u.email as creator_email,
    COUNT(DISTINCT pc.user_id) as contributor_count,
    COUNT(DISTINCT poly.id) as polygon_count,
    COUNT(DISTINCT pt.id) as point_count,
    COUNT(DISTINCT poly.id) + COUNT(DISTINCT pt.id) as total_features
FROM projects p
JOIN users u ON p.created_by = u.id
LEFT JOIN project_contributors pc ON p.id = pc.project_id
LEFT JOIN polygones poly ON p.id = poly.project_id
LEFT JOIN points pt ON p.id = pt.project_id
GROUP BY p.id, p.name, p.description, p.project_type, p.is_active, p.start_date, p.end_date, u.email;

-- Function to add user to project
CREATE OR REPLACE FUNCTION add_user_to_project(
    p_project_id INTEGER,
    p_user_id VARCHAR
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO project_contributors (project_id, user_id)
    VALUES (p_project_id, p_user_id)
    ON CONFLICT (project_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Function to remove user from project
CREATE OR REPLACE FUNCTION remove_user_from_project(
    p_project_id INTEGER,
    p_user_id VARCHAR
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM project_contributors
    WHERE project_id = p_project_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to project
CREATE OR REPLACE FUNCTION user_has_project_access(
    p_project_id INTEGER,
    p_user_id VARCHAR
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

-- Comments for documentation
COMMENT ON TABLE users IS 'User accounts with roles and contribution tracking';
COMMENT ON TABLE polygones IS 'Agricultural land parcels as polygons with geospatial data';
COMMENT ON TABLE points IS 'Individual crop location points with geospatial data';
COMMENT ON TABLE projects IS 'Data collection projects created by admins';
COMMENT ON TABLE project_contributors IS 'Many-to-many relationship between projects and contributors';
COMMENT ON COLUMN polygones.geometry IS 'PostGIS polygon geometry in WGS84 (SRID 4326)';
COMMENT ON COLUMN points.geometry IS 'PostGIS point geometry in WGS84 (SRID 4326)';
COMMENT ON COLUMN polygones.project_id IS 'Optional reference to project this polygon belongs to';
COMMENT ON COLUMN points.project_id IS 'Optional reference to project this point belongs to';

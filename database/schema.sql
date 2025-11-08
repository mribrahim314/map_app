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

-- Comments for documentation
COMMENT ON TABLE users IS 'User accounts with roles and contribution tracking';
COMMENT ON TABLE polygones IS 'Agricultural land parcels as polygons with geospatial data';
COMMENT ON TABLE points IS 'Individual crop location points with geospatial data';
COMMENT ON COLUMN polygones.geometry IS 'PostGIS polygon geometry in WGS84 (SRID 4326)';
COMMENT ON COLUMN points.geometry IS 'PostGIS point geometry in WGS84 (SRID 4326)';

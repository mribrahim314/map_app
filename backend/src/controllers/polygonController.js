const { query, getClient } = require('../config/database');

/**
 * Polygon Controller
 * Handles polygon CRUD operations with PostGIS spatial support
 */

/**
 * Create a new polygon
 * POST /api/polygons
 */
exports.createPolygon = async (req, res, next) => {
  try {
    const {
      coordinates, // Array of [lat, lng] points
      cropType,
      area,
      perimeter,
      notes,
      projectId,
      images = [],
    } = req.body;

    const userId = req.user.id;

    // Convert coordinates to PostGIS POLYGON format
    // Expected format: [[lat1, lng1], [lat2, lng2], ...]
    // PostGIS format: POLYGON((lng1 lat1, lng2 lat2, ..., lng1 lat1))
    const polygonCoords = coordinates.map(coord => `${coord[1]} ${coord[0]}`).join(', ');
    const firstCoord = `${coordinates[0][1]} ${coordinates[0][0]}`;
    const wktPolygon = `POLYGON((${polygonCoords}, ${firstCoord}))`;

    const result = await query(
      `INSERT INTO polygones (
        user_id, crop_type, area, perimeter, notes, project_id,
        images, geometry, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, ST_GeomFromText($8, 4326), NOW())
      RETURNING
        id,
        user_id,
        crop_type,
        area,
        perimeter,
        notes,
        project_id,
        images,
        ST_AsGeoJSON(geometry) as geometry,
        created_at`,
      [userId, cropType, area, perimeter, notes, projectId, JSON.stringify(images), wktPolygon]
    );

    // Update user contribution count
    await query(
      'UPDATE users SET polygones_contributed = polygones_contributed + 1 WHERE id = $1',
      [userId]
    );

    const polygon = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Polygon created successfully',
      data: {
        id: polygon.id,
        userId: polygon.user_id,
        cropType: polygon.crop_type,
        area: polygon.area,
        perimeter: polygon.perimeter,
        notes: polygon.notes,
        projectId: polygon.project_id,
        images: JSON.parse(polygon.images),
        geometry: JSON.parse(polygon.geometry),
        createdAt: polygon.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get all polygons with filters
 * GET /api/polygons
 */
exports.getAllPolygons = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 50,
      cropType,
      projectId,
      userId,
      minArea,
      maxArea,
    } = req.query;

    const offset = (page - 1) * limit;

    let queryText = `
      SELECT
        p.id,
        p.user_id,
        p.crop_type,
        p.area,
        p.perimeter,
        p.notes,
        p.project_id,
        p.images,
        p.created_at,
        ST_AsGeoJSON(p.geometry) as geometry,
        u.first_name,
        u.last_name,
        u.email
      FROM polygones p
      JOIN users u ON p.user_id = u.id
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (cropType) {
      queryText += ` AND p.crop_type = $${paramCount}`;
      params.push(cropType);
      paramCount++;
    }

    if (projectId) {
      queryText += ` AND p.project_id = $${paramCount}`;
      params.push(projectId);
      paramCount++;
    }

    if (userId) {
      queryText += ` AND p.user_id = $${paramCount}`;
      params.push(userId);
      paramCount++;
    }

    if (minArea) {
      queryText += ` AND p.area >= $${paramCount}`;
      params.push(parseFloat(minArea));
      paramCount++;
    }

    if (maxArea) {
      queryText += ` AND p.area <= $${paramCount}`;
      params.push(parseFloat(maxArea));
      paramCount++;
    }

    queryText += ` ORDER BY p.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM polygones WHERE 1=1';
    const countParams = [];
    let countIndex = 1;

    if (cropType) {
      countQuery += ` AND crop_type = $${countIndex}`;
      countParams.push(cropType);
      countIndex++;
    }

    if (projectId) {
      countQuery += ` AND project_id = $${countIndex}`;
      countParams.push(projectId);
      countIndex++;
    }

    if (userId) {
      countQuery += ` AND user_id = $${countIndex}`;
      countParams.push(userId);
      countIndex++;
    }

    if (minArea) {
      countQuery += ` AND area >= $${countIndex}`;
      countParams.push(parseFloat(minArea));
      countIndex++;
    }

    if (maxArea) {
      countQuery += ` AND area <= $${countIndex}`;
      countParams.push(parseFloat(maxArea));
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        polygons: result.rows.map((p) => ({
          id: p.id,
          userId: p.user_id,
          cropType: p.crop_type,
          area: p.area,
          perimeter: p.perimeter,
          notes: p.notes,
          projectId: p.project_id,
          images: JSON.parse(p.images),
          geometry: JSON.parse(p.geometry),
          createdAt: p.created_at,
          user: {
            firstName: p.first_name,
            lastName: p.last_name,
            email: p.email,
          },
        })),
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get polygon by ID
 * GET /api/polygons/:id
 */
exports.getPolygonById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT
        p.id,
        p.user_id,
        p.crop_type,
        p.area,
        p.perimeter,
        p.notes,
        p.project_id,
        p.images,
        p.created_at,
        ST_AsGeoJSON(p.geometry) as geometry,
        u.first_name,
        u.last_name,
        u.email
      FROM polygones p
      JOIN users u ON p.user_id = u.id
      WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Polygon not found',
      });
    }

    const p = result.rows[0];

    res.json({
      success: true,
      data: {
        id: p.id,
        userId: p.user_id,
        cropType: p.crop_type,
        area: p.area,
        perimeter: p.perimeter,
        notes: p.notes,
        projectId: p.project_id,
        images: JSON.parse(p.images),
        geometry: JSON.parse(p.geometry),
        createdAt: p.created_at,
        user: {
          firstName: p.first_name,
          lastName: p.last_name,
          email: p.email,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update polygon
 * PUT /api/polygons/:id
 */
exports.updatePolygon = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { cropType, notes, images } = req.body;

    // Check if polygon exists and user owns it (or is admin)
    const existing = await query('SELECT user_id FROM polygones WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Polygon not found',
      });
    }

    if (existing.rows[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own polygons',
      });
    }

    const updates = [];
    const params = [];
    let paramCount = 1;

    if (cropType !== undefined) {
      updates.push(`crop_type = $${paramCount}`);
      params.push(cropType);
      paramCount++;
    }

    if (notes !== undefined) {
      updates.push(`notes = $${paramCount}`);
      params.push(notes);
      paramCount++;
    }

    if (images !== undefined) {
      updates.push(`images = $${paramCount}`);
      params.push(JSON.stringify(images));
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update',
      });
    }

    params.push(id);

    const result = await query(
      `UPDATE polygones SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING
         id, user_id, crop_type, area, perimeter, notes, project_id,
         images, ST_AsGeoJSON(geometry) as geometry, created_at`,
      params
    );

    const p = result.rows[0];

    res.json({
      success: true,
      message: 'Polygon updated successfully',
      data: {
        id: p.id,
        userId: p.user_id,
        cropType: p.crop_type,
        area: p.area,
        perimeter: p.perimeter,
        notes: p.notes,
        projectId: p.project_id,
        images: JSON.parse(p.images),
        geometry: JSON.parse(p.geometry),
        createdAt: p.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete polygon
 * DELETE /api/polygons/:id
 */
exports.deletePolygon = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if polygon exists and user owns it (or is admin)
    const existing = await query('SELECT user_id FROM polygones WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Polygon not found',
      });
    }

    if (existing.rows[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own polygons',
      });
    }

    const userId = existing.rows[0].user_id;

    await query('DELETE FROM polygones WHERE id = $1', [id]);

    // Update user contribution count
    await query(
      'UPDATE users SET polygones_contributed = GREATEST(0, polygones_contributed - 1) WHERE id = $1',
      [userId]
    );

    res.json({
      success: true,
      message: 'Polygon deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get polygons within bounds
 * POST /api/polygons/within-bounds
 */
exports.getPolygonsWithinBounds = async (req, res, next) => {
  try {
    const { northEast, southWest } = req.body;

    // Create bounding box
    const bbox = `POLYGON((
      ${southWest.lng} ${southWest.lat},
      ${northEast.lng} ${southWest.lat},
      ${northEast.lng} ${northEast.lat},
      ${southWest.lng} ${northEast.lat},
      ${southWest.lng} ${southWest.lat}
    ))`;

    const result = await query(
      `SELECT
        p.id,
        p.user_id,
        p.crop_type,
        p.area,
        p.perimeter,
        p.notes,
        p.project_id,
        p.images,
        p.created_at,
        ST_AsGeoJSON(p.geometry) as geometry
      FROM polygones p
      WHERE ST_Intersects(p.geometry, ST_GeomFromText($1, 4326))
      ORDER BY p.created_at DESC`,
      [bbox]
    );

    res.json({
      success: true,
      data: {
        polygons: result.rows.map((p) => ({
          id: p.id,
          userId: p.user_id,
          cropType: p.crop_type,
          area: p.area,
          perimeter: p.perimeter,
          notes: p.notes,
          projectId: p.project_id,
          images: JSON.parse(p.images),
          geometry: JSON.parse(p.geometry),
          createdAt: p.created_at,
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};

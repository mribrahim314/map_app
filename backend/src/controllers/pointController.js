const { query } = require('../config/database');

/**
 * Point Controller
 * Handles point CRUD operations with PostGIS spatial support
 */

/**
 * Create a new point
 * POST /api/points
 */
exports.createPoint = async (req, res, next) => {
  try {
    const {
      latitude,
      longitude,
      cropType,
      notes,
      projectId,
      images = [],
    } = req.body;

    const userId = req.user.id;

    // Create PostGIS POINT geometry
    const wktPoint = `POINT(${longitude} ${latitude})`;

    const result = await query(
      `INSERT INTO points (
        user_id, crop_type, notes, project_id, images,
        geometry, created_at
      )
      VALUES ($1, $2, $3, $4, $5, ST_GeomFromText($6, 4326), NOW())
      RETURNING
        id,
        user_id,
        crop_type,
        notes,
        project_id,
        images,
        ST_AsGeoJSON(geometry) as geometry,
        created_at`,
      [userId, cropType, notes, projectId, JSON.stringify(images), wktPoint]
    );

    // Update user contribution count
    await query(
      'UPDATE users SET points_contributed = points_contributed + 1 WHERE id = $1',
      [userId]
    );

    const point = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Point created successfully',
      data: {
        id: point.id,
        userId: point.user_id,
        cropType: point.crop_type,
        notes: point.notes,
        projectId: point.project_id,
        images: JSON.parse(point.images),
        geometry: JSON.parse(point.geometry),
        createdAt: point.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get all points with filters
 * GET /api/points
 */
exports.getAllPoints = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 50,
      cropType,
      projectId,
      userId,
    } = req.query;

    const offset = (page - 1) * limit;

    let queryText = `
      SELECT
        p.id,
        p.user_id,
        p.crop_type,
        p.notes,
        p.project_id,
        p.images,
        p.created_at,
        ST_AsGeoJSON(p.geometry) as geometry,
        u.first_name,
        u.last_name,
        u.email
      FROM points p
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

    queryText += ` ORDER BY p.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM points WHERE 1=1';
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
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        points: result.rows.map((p) => ({
          id: p.id,
          userId: p.user_id,
          cropType: p.crop_type,
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
 * Get point by ID
 * GET /api/points/:id
 */
exports.getPointById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT
        p.id,
        p.user_id,
        p.crop_type,
        p.notes,
        p.project_id,
        p.images,
        p.created_at,
        ST_AsGeoJSON(p.geometry) as geometry,
        u.first_name,
        u.last_name,
        u.email
      FROM points p
      JOIN users u ON p.user_id = u.id
      WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Point not found',
      });
    }

    const p = result.rows[0];

    res.json({
      success: true,
      data: {
        id: p.id,
        userId: p.user_id,
        cropType: p.crop_type,
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
 * Update point
 * PUT /api/points/:id
 */
exports.updatePoint = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { cropType, notes, images } = req.body;

    // Check if point exists and user owns it (or is admin)
    const existing = await query('SELECT user_id FROM points WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Point not found',
      });
    }

    if (existing.rows[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own points',
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
      `UPDATE points SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING
         id, user_id, crop_type, notes, project_id,
         images, ST_AsGeoJSON(geometry) as geometry, created_at`,
      params
    );

    const p = result.rows[0];

    res.json({
      success: true,
      message: 'Point updated successfully',
      data: {
        id: p.id,
        userId: p.user_id,
        cropType: p.crop_type,
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
 * Delete point
 * DELETE /api/points/:id
 */
exports.deletePoint = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if point exists and user owns it (or is admin)
    const existing = await query('SELECT user_id FROM points WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Point not found',
      });
    }

    if (existing.rows[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own points',
      });
    }

    const userId = existing.rows[0].user_id;

    await query('DELETE FROM points WHERE id = $1', [id]);

    // Update user contribution count
    await query(
      'UPDATE users SET points_contributed = GREATEST(0, points_contributed - 1) WHERE id = $1',
      [userId]
    );

    res.json({
      success: true,
      message: 'Point deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get points within bounds
 * POST /api/points/within-bounds
 */
exports.getPointsWithinBounds = async (req, res, next) => {
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
        p.notes,
        p.project_id,
        p.images,
        p.created_at,
        ST_AsGeoJSON(p.geometry) as geometry
      FROM points p
      WHERE ST_Within(p.geometry, ST_GeomFromText($1, 4326))
      ORDER BY p.created_at DESC`,
      [bbox]
    );

    res.json({
      success: true,
      data: {
        points: result.rows.map((p) => ({
          id: p.id,
          userId: p.user_id,
          cropType: p.crop_type,
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

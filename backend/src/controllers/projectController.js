const { query, getClient } = require('../config/database');

/**
 * Project Controller
 * Handles project CRUD operations and contributor management
 */

/**
 * Create a new project
 * POST /api/projects
 */
exports.createProject = async (req, res, next) => {
  try {
    const {
      name,
      description,
      startDate,
      endDate,
      targetArea,
      status = 'active',
    } = req.body;

    const createdBy = req.user.id;

    const result = await query(
      `INSERT INTO projects (
        name, description, start_date, end_date,
        target_area, status, created_by, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
      RETURNING
        id, name, description, start_date, end_date,
        target_area, status, created_by, created_at`,
      [name, description, startDate, endDate, targetArea, status, createdBy]
    );

    const project = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Project created successfully',
      data: {
        id: project.id,
        name: project.name,
        description: project.description,
        startDate: project.start_date,
        endDate: project.end_date,
        targetArea: project.target_area,
        status: project.status,
        createdBy: project.created_by,
        createdAt: project.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get all projects
 * GET /api/projects
 */
exports.getAllProjects = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, status, search } = req.query;
    const offset = (page - 1) * limit;

    let queryText = `
      SELECT
        p.id,
        p.name,
        p.description,
        p.start_date,
        p.end_date,
        p.target_area,
        p.status,
        p.created_by,
        p.created_at,
        u.first_name as creator_first_name,
        u.last_name as creator_last_name,
        u.email as creator_email,
        COUNT(DISTINCT pc.user_id) as contributor_count,
        COUNT(DISTINCT poly.id) as polygon_count,
        COUNT(DISTINCT pt.id) as point_count
      FROM projects p
      JOIN users u ON p.created_by = u.id
      LEFT JOIN project_contributors pc ON p.id = pc.project_id
      LEFT JOIN polygones poly ON p.id = poly.project_id
      LEFT JOIN points pt ON p.id = pt.project_id
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (status) {
      queryText += ` AND p.status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    if (search) {
      queryText += ` AND (
        p.name ILIKE $${paramCount} OR
        p.description ILIKE $${paramCount}
      )`;
      params.push(`%${search}%`);
      paramCount++;
    }

    queryText += ` GROUP BY p.id, u.id
                   ORDER BY p.created_at DESC
                   LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM projects WHERE 1=1';
    const countParams = [];
    let countIndex = 1;

    if (status) {
      countQuery += ` AND status = $${countIndex}`;
      countParams.push(status);
      countIndex++;
    }

    if (search) {
      countQuery += ` AND (name ILIKE $${countIndex} OR description ILIKE $${countIndex})`;
      countParams.push(`%${search}%`);
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        projects: result.rows.map((p) => ({
          id: p.id,
          name: p.name,
          description: p.description,
          startDate: p.start_date,
          endDate: p.end_date,
          targetArea: p.target_area,
          status: p.status,
          createdBy: p.created_by,
          createdAt: p.created_at,
          creator: {
            firstName: p.creator_first_name,
            lastName: p.creator_last_name,
            email: p.creator_email,
          },
          stats: {
            contributorCount: parseInt(p.contributor_count),
            polygonCount: parseInt(p.polygon_count),
            pointCount: parseInt(p.point_count),
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
 * Get project by ID
 * GET /api/projects/:id
 */
exports.getProjectById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT
        p.id,
        p.name,
        p.description,
        p.start_date,
        p.end_date,
        p.target_area,
        p.status,
        p.created_by,
        p.created_at,
        u.first_name as creator_first_name,
        u.last_name as creator_last_name,
        u.email as creator_email
      FROM projects p
      JOIN users u ON p.created_by = u.id
      WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Project not found',
      });
    }

    const p = result.rows[0];

    // Get contributors
    const contributors = await query(
      `SELECT
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        pc.joined_at
      FROM project_contributors pc
      JOIN users u ON pc.user_id = u.id
      WHERE pc.project_id = $1
      ORDER BY pc.joined_at DESC`,
      [id]
    );

    res.json({
      success: true,
      data: {
        id: p.id,
        name: p.name,
        description: p.description,
        startDate: p.start_date,
        endDate: p.end_date,
        targetArea: p.target_area,
        status: p.status,
        createdBy: p.created_by,
        createdAt: p.created_at,
        creator: {
          firstName: p.creator_first_name,
          lastName: p.creator_last_name,
          email: p.creator_email,
        },
        contributors: contributors.rows.map((c) => ({
          id: c.id,
          email: c.email,
          firstName: c.first_name,
          lastName: c.last_name,
          joinedAt: c.joined_at,
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update project
 * PUT /api/projects/:id
 */
exports.updateProject = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, description, startDate, endDate, targetArea, status } = req.body;

    // Check if project exists
    const existing = await query('SELECT created_by FROM projects WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Project not found',
      });
    }

    // Check if user is creator or admin
    if (existing.rows[0].created_by !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only project creator or admin can update this project',
      });
    }

    const updates = [];
    const params = [];
    let paramCount = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramCount}`);
      params.push(name);
      paramCount++;
    }

    if (description !== undefined) {
      updates.push(`description = $${paramCount}`);
      params.push(description);
      paramCount++;
    }

    if (startDate !== undefined) {
      updates.push(`start_date = $${paramCount}`);
      params.push(startDate);
      paramCount++;
    }

    if (endDate !== undefined) {
      updates.push(`end_date = $${paramCount}`);
      params.push(endDate);
      paramCount++;
    }

    if (targetArea !== undefined) {
      updates.push(`target_area = $${paramCount}`);
      params.push(targetArea);
      paramCount++;
    }

    if (status !== undefined) {
      updates.push(`status = $${paramCount}`);
      params.push(status);
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
      `UPDATE projects SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING
         id, name, description, start_date, end_date,
         target_area, status, created_by, created_at`,
      params
    );

    const p = result.rows[0];

    res.json({
      success: true,
      message: 'Project updated successfully',
      data: {
        id: p.id,
        name: p.name,
        description: p.description,
        startDate: p.start_date,
        endDate: p.end_date,
        targetArea: p.target_area,
        status: p.status,
        createdBy: p.created_by,
        createdAt: p.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete project
 * DELETE /api/projects/:id
 */
exports.deleteProject = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if project exists
    const existing = await query('SELECT created_by FROM projects WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Project not found',
      });
    }

    // Check if user is creator or admin
    if (existing.rows[0].created_by !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only project creator or admin can delete this project',
      });
    }

    await query('DELETE FROM projects WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'Project deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Add contributor to project
 * POST /api/projects/:id/contributors
 */
exports.addContributor = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    // Check if project exists
    const project = await query('SELECT id FROM projects WHERE id = $1', [id]);

    if (project.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Project not found',
      });
    }

    // Check if user exists
    const user = await query('SELECT id FROM users WHERE id = $1', [userId]);

    if (user.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if already a contributor
    const existing = await query(
      'SELECT * FROM project_contributors WHERE project_id = $1 AND user_id = $2',
      [id, userId]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'User is already a contributor',
      });
    }

    await query(
      'INSERT INTO project_contributors (project_id, user_id, joined_at) VALUES ($1, $2, NOW())',
      [id, userId]
    );

    res.status(201).json({
      success: true,
      message: 'Contributor added successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Remove contributor from project
 * DELETE /api/projects/:id/contributors/:userId
 */
exports.removeContributor = async (req, res, next) => {
  try {
    const { id, userId } = req.params;

    const result = await query(
      'DELETE FROM project_contributors WHERE project_id = $1 AND user_id = $2 RETURNING *',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contributor not found in this project',
      });
    }

    res.json({
      success: true,
      message: 'Contributor removed successfully',
    });
  } catch (error) {
    next(error);
  }
};

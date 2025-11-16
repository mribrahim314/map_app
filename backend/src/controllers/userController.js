const { query } = require('../config/database');
const bcrypt = require('bcrypt');
const config = require('../config/config');

/**
 * User Controller
 * Handles user CRUD operations and user management
 */

/**
 * Get all users (Admin only)
 * GET /api/users
 */
exports.getAllUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, role, search } = req.query;
    const offset = (page - 1) * limit;

    let queryText = `
      SELECT id, email, first_name, last_name, role,
             points_contributed, polygones_contributed,
             created_at, last_login
      FROM users
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;

    // Filter by role
    if (role) {
      queryText += ` AND role = $${paramCount}`;
      params.push(role);
      paramCount++;
    }

    // Search by email or name
    if (search) {
      queryText += ` AND (
        email ILIKE $${paramCount} OR
        first_name ILIKE $${paramCount} OR
        last_name ILIKE $${paramCount}
      )`;
      params.push(`%${search}%`);
      paramCount++;
    }

    queryText += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM users WHERE 1=1';
    const countParams = [];
    let countParamIndex = 1;

    if (role) {
      countQuery += ` AND role = $${countParamIndex}`;
      countParams.push(role);
      countParamIndex++;
    }

    if (search) {
      countQuery += ` AND (
        email ILIKE $${countParamIndex} OR
        first_name ILIKE $${countParamIndex} OR
        last_name ILIKE $${countParamIndex}
      )`;
      countParams.push(`%${search}%`);
    }

    const countResult = await query(countQuery, countParams);
    const totalUsers = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        users: result.rows.map((user) => ({
          id: user.id,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          role: user.role,
          pointsContributed: user.points_contributed,
          polygonesContributed: user.polygones_contributed,
          createdAt: user.created_at,
          lastLogin: user.last_login,
        })),
        pagination: {
          total: totalUsers,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(totalUsers / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user by ID
 * GET /api/users/:id
 */
exports.getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT id, email, first_name, last_name, role,
              points_contributed, polygones_contributed,
              created_at, last_login
       FROM users WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        pointsContributed: user.points_contributed,
        polygonesContributed: user.polygones_contributed,
        createdAt: user.created_at,
        lastLogin: user.last_login,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user
 * PUT /api/users/:id
 */
exports.updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { firstName, lastName, email, role, password } = req.body;

    // Check if user exists
    const existingUser = await query('SELECT id FROM users WHERE id = $1', [id]);

    if (existingUser.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if requesting user is updating their own account or is admin
    if (req.user.id !== id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own account',
      });
    }

    // Build update query dynamically
    const updates = [];
    const params = [];
    let paramCount = 1;

    if (firstName !== undefined) {
      updates.push(`first_name = $${paramCount}`);
      params.push(firstName);
      paramCount++;
    }

    if (lastName !== undefined) {
      updates.push(`last_name = $${paramCount}`);
      params.push(lastName);
      paramCount++;
    }

    if (email !== undefined) {
      updates.push(`email = $${paramCount}`);
      params.push(email);
      paramCount++;
    }

    // Only admin can change roles
    if (role !== undefined && req.user.role === 'admin') {
      updates.push(`role = $${paramCount}`);
      params.push(role);
      paramCount++;
    }

    if (password !== undefined) {
      const hashedPassword = await bcrypt.hash(password, config.security.bcryptRounds);
      updates.push(`password_hash = $${paramCount}`);
      params.push(hashedPassword);
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
      `UPDATE users SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING id, email, first_name, last_name, role, created_at`,
      params
    );

    const user = result.rows[0];

    res.json({
      success: true,
      message: 'User updated successfully',
      data: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        createdAt: user.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete user
 * DELETE /api/users/:id
 */
exports.deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if user exists
    const existingUser = await query('SELECT id FROM users WHERE id = $1', [id]);

    if (existingUser.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Prevent users from deleting themselves
    if (req.user.id === id) {
      return res.status(400).json({
        success: false,
        message: 'You cannot delete your own account',
      });
    }

    await query('DELETE FROM users WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'User deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user statistics
 * GET /api/users/:id/stats
 */
exports.getUserStats = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.points_contributed,
        u.polygones_contributed,
        COUNT(DISTINCT pc.project_id) as projects_count
       FROM users u
       LEFT JOIN project_contributors pc ON u.id = pc.user_id
       WHERE u.id = $1
       GROUP BY u.id`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      data: {
        userId: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        statistics: {
          pointsContributed: user.points_contributed,
          polygonesContributed: user.polygones_contributed,
          projectsCount: parseInt(user.projects_count),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

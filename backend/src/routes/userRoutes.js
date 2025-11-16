const express = require('express');
const { body, param, query } = require('express-validator');
const userController = require('../controllers/userController');
const { authenticateToken, authorize } = require('../middleware/auth');
const validate = require('../middleware/validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

/**
 * @route   GET /api/users
 * @desc    Get all users (paginated, with filters)
 * @access  Private (Admin only)
 */
router.get(
  '/',
  authorize('admin'),
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('role').optional().isIn(['user', 'admin']).withMessage('Role must be user or admin'),
    query('search').optional().isString().trim(),
  ],
  validate,
  userController.getAllUsers
);

/**
 * @route   GET /api/users/:id
 * @desc    Get user by ID
 * @access  Private
 */
router.get(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid user ID format'),
  ],
  validate,
  userController.getUserById
);

/**
 * @route   PUT /api/users/:id
 * @desc    Update user (own account or admin)
 * @access  Private
 */
router.put(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid user ID format'),
    body('firstName').optional().trim().notEmpty().withMessage('First name cannot be empty'),
    body('lastName').optional().trim().notEmpty().withMessage('Last name cannot be empty'),
    body('email').optional().isEmail().withMessage('Invalid email format').normalizeEmail(),
    body('role').optional().isIn(['user', 'admin']).withMessage('Role must be user or admin'),
    body('password').optional().isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  validate,
  userController.updateUser
);

/**
 * @route   DELETE /api/users/:id
 * @desc    Delete user
 * @access  Private (Admin only)
 */
router.delete(
  '/:id',
  authorize('admin'),
  [
    param('id').isUUID().withMessage('Invalid user ID format'),
  ],
  validate,
  userController.deleteUser
);

/**
 * @route   GET /api/users/:id/stats
 * @desc    Get user statistics
 * @access  Private
 */
router.get(
  '/:id/stats',
  [
    param('id').isUUID().withMessage('Invalid user ID format'),
  ],
  validate,
  userController.getUserStats
);

module.exports = router;

const express = require('express');
const { body, param, query } = require('express-validator');
const projectController = require('../controllers/projectController');
const { authenticateToken, authorize } = require('../middleware/auth');
const validate = require('../middleware/validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

/**
 * @route   POST /api/projects
 * @desc    Create a new project
 * @access  Private
 */
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Project name is required'),
    body('description').optional().trim(),
    body('startDate').optional().isISO8601().withMessage('Invalid start date format'),
    body('endDate').optional().isISO8601().withMessage('Invalid end date format'),
    body('targetArea').optional().isFloat({ min: 0 }).withMessage('Target area must be positive'),
    body('status')
      .optional()
      .isIn(['active', 'completed', 'cancelled'])
      .withMessage('Status must be active, completed, or cancelled'),
  ],
  validate,
  projectController.createProject
);

/**
 * @route   GET /api/projects
 * @desc    Get all projects
 * @access  Private
 */
router.get(
  '/',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('status')
      .optional()
      .isIn(['active', 'completed', 'cancelled'])
      .withMessage('Status must be active, completed, or cancelled'),
    query('search').optional().trim(),
  ],
  validate,
  projectController.getAllProjects
);

/**
 * @route   GET /api/projects/:id
 * @desc    Get project by ID
 * @access  Private
 */
router.get(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid project ID format'),
  ],
  validate,
  projectController.getProjectById
);

/**
 * @route   PUT /api/projects/:id
 * @desc    Update project
 * @access  Private
 */
router.put(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid project ID format'),
    body('name').optional().trim().notEmpty().withMessage('Project name cannot be empty'),
    body('description').optional().trim(),
    body('startDate').optional().isISO8601().withMessage('Invalid start date format'),
    body('endDate').optional().isISO8601().withMessage('Invalid end date format'),
    body('targetArea').optional().isFloat({ min: 0 }).withMessage('Target area must be positive'),
    body('status')
      .optional()
      .isIn(['active', 'completed', 'cancelled'])
      .withMessage('Status must be active, completed, or cancelled'),
  ],
  validate,
  projectController.updateProject
);

/**
 * @route   DELETE /api/projects/:id
 * @desc    Delete project
 * @access  Private
 */
router.delete(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid project ID format'),
  ],
  validate,
  projectController.deleteProject
);

/**
 * @route   POST /api/projects/:id/contributors
 * @desc    Add contributor to project
 * @access  Private
 */
router.post(
  '/:id/contributors',
  [
    param('id').isUUID().withMessage('Invalid project ID format'),
    body('userId').isUUID().withMessage('Invalid user ID format'),
  ],
  validate,
  projectController.addContributor
);

/**
 * @route   DELETE /api/projects/:id/contributors/:userId
 * @desc    Remove contributor from project
 * @access  Private
 */
router.delete(
  '/:id/contributors/:userId',
  [
    param('id').isUUID().withMessage('Invalid project ID format'),
    param('userId').isUUID().withMessage('Invalid user ID format'),
  ],
  validate,
  projectController.removeContributor
);

module.exports = router;

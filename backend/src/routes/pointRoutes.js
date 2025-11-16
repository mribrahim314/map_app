const express = require('express');
const { body, param, query } = require('express-validator');
const pointController = require('../controllers/pointController');
const { authenticateToken } = require('../middleware/auth');
const validate = require('../middleware/validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

/**
 * @route   POST /api/points
 * @desc    Create a new point
 * @access  Private
 */
router.post(
  '/',
  [
    body('latitude')
      .isFloat({ min: -90, max: 90 })
      .withMessage('Latitude must be between -90 and 90'),
    body('longitude')
      .isFloat({ min: -180, max: 180 })
      .withMessage('Longitude must be between -180 and 180'),
    body('cropType').trim().notEmpty().withMessage('Crop type is required'),
    body('notes').optional().trim(),
    body('projectId').optional().isUUID().withMessage('Invalid project ID format'),
    body('images').optional().isArray().withMessage('Images must be an array'),
  ],
  validate,
  pointController.createPoint
);

/**
 * @route   GET /api/points
 * @desc    Get all points with filters
 * @access  Private
 */
router.get(
  '/',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('cropType').optional().trim(),
    query('projectId').optional().isUUID().withMessage('Invalid project ID format'),
    query('userId').optional().isUUID().withMessage('Invalid user ID format'),
  ],
  validate,
  pointController.getAllPoints
);

/**
 * @route   GET /api/points/:id
 * @desc    Get point by ID
 * @access  Private
 */
router.get(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid point ID format'),
  ],
  validate,
  pointController.getPointById
);

/**
 * @route   PUT /api/points/:id
 * @desc    Update point
 * @access  Private
 */
router.put(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid point ID format'),
    body('cropType').optional().trim().notEmpty().withMessage('Crop type cannot be empty'),
    body('notes').optional().trim(),
    body('images').optional().isArray().withMessage('Images must be an array'),
  ],
  validate,
  pointController.updatePoint
);

/**
 * @route   DELETE /api/points/:id
 * @desc    Delete point
 * @access  Private
 */
router.delete(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid point ID format'),
  ],
  validate,
  pointController.deletePoint
);

/**
 * @route   POST /api/points/within-bounds
 * @desc    Get points within map bounds
 * @access  Private
 */
router.post(
  '/within-bounds',
  [
    body('northEast').isObject().withMessage('northEast must be an object'),
    body('northEast.lat').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
    body('northEast.lng').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
    body('southWest').isObject().withMessage('southWest must be an object'),
    body('southWest.lat').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
    body('southWest.lng').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  ],
  validate,
  pointController.getPointsWithinBounds
);

module.exports = router;

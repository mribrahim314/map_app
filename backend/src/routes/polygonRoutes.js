const express = require('express');
const { body, param, query } = require('express-validator');
const polygonController = require('../controllers/polygonController');
const { authenticateToken } = require('../middleware/auth');
const validate = require('../middleware/validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

/**
 * @route   POST /api/polygons
 * @desc    Create a new polygon
 * @access  Private
 */
router.post(
  '/',
  [
    body('coordinates')
      .isArray({ min: 3 })
      .withMessage('Coordinates must be an array with at least 3 points'),
    body('coordinates.*')
      .isArray({ min: 2, max: 2 })
      .withMessage('Each coordinate must be [lat, lng]'),
    body('cropType').trim().notEmpty().withMessage('Crop type is required'),
    body('area').optional().isFloat({ min: 0 }).withMessage('Area must be a positive number'),
    body('perimeter').optional().isFloat({ min: 0 }).withMessage('Perimeter must be a positive number'),
    body('notes').optional().trim(),
    body('projectId').optional().isUUID().withMessage('Invalid project ID format'),
    body('images').optional().isArray().withMessage('Images must be an array'),
  ],
  validate,
  polygonController.createPolygon
);

/**
 * @route   GET /api/polygons
 * @desc    Get all polygons with filters
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
    query('minArea').optional().isFloat({ min: 0 }).withMessage('Min area must be a positive number'),
    query('maxArea').optional().isFloat({ min: 0 }).withMessage('Max area must be a positive number'),
  ],
  validate,
  polygonController.getAllPolygons
);

/**
 * @route   GET /api/polygons/:id
 * @desc    Get polygon by ID
 * @access  Private
 */
router.get(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid polygon ID format'),
  ],
  validate,
  polygonController.getPolygonById
);

/**
 * @route   PUT /api/polygons/:id
 * @desc    Update polygon
 * @access  Private
 */
router.put(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid polygon ID format'),
    body('cropType').optional().trim().notEmpty().withMessage('Crop type cannot be empty'),
    body('notes').optional().trim(),
    body('images').optional().isArray().withMessage('Images must be an array'),
  ],
  validate,
  polygonController.updatePolygon
);

/**
 * @route   DELETE /api/polygons/:id
 * @desc    Delete polygon
 * @access  Private
 */
router.delete(
  '/:id',
  [
    param('id').isUUID().withMessage('Invalid polygon ID format'),
  ],
  validate,
  polygonController.deletePolygon
);

/**
 * @route   POST /api/polygons/within-bounds
 * @desc    Get polygons within map bounds
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
  polygonController.getPolygonsWithinBounds
);

module.exports = router;

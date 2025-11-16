require('dotenv').config();

/**
 * Application Configuration
 * Centralized configuration management for all environment variables
 */
module.exports = {
  // Server Configuration
  server: {
    port: process.env.PORT || 3000,
    env: process.env.NODE_ENV || 'development',
  },

  // Database Configuration
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    name: process.env.DB_NAME || 'map_app',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
  },

  // JWT Configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  // CORS Configuration
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },

  // Security Configuration
  security: {
    bcryptRounds: 10, // Number of bcrypt salt rounds
    maxLoginAttempts: 5, // Maximum login attempts before lockout
    loginTimeout: 15 * 60 * 1000, // 15 minutes in milliseconds
  },
};

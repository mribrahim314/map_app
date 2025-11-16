# Map App Backend API

RESTful API backend for the Map Application, built with Node.js, Express, and PostgreSQL with PostGIS support.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Authentication](#authentication)
- [Error Handling](#error-handling)
- [Development](#development)

## Features

- **JWT Authentication** - Secure user authentication with JSON Web Tokens
- **Role-Based Access Control** - Admin and user roles with different permissions
- **PostGIS Support** - Spatial queries for geographic data (polygons and points)
- **Input Validation** - Request validation using express-validator
- **Security** - Helmet, CORS, bcrypt password hashing
- **Error Handling** - Centralized error handling middleware
- **Database Connection Pooling** - Efficient PostgreSQL connection management

## Tech Stack

- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** PostgreSQL with PostGIS extension
- **Authentication:** JWT (jsonwebtoken)
- **Password Hashing:** bcrypt
- **Validation:** express-validator
- **Security:** Helmet, CORS
- **Logging:** Morgan

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- PostgreSQL (v12 or higher) with PostGIS extension
- npm or yarn

### Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables:
```bash
cp .env.example .env
```

Edit `.env` and update the following:
```env
PORT=3000
NODE_ENV=development

DB_HOST=localhost
DB_PORT=5432
DB_NAME=map_app
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

CORS_ORIGIN=*
```

4. Ensure PostgreSQL database is set up:
```bash
# Option 1: Run all migrations automatically (recommended)
cd ../database
./run_migrations.sh

# Option 2: Run migrations manually
psql -U postgres -d map_app -f ../database/schema.sql
psql -U postgres -d map_app -f ../database/migration_001_align_schema.sql
psql -U postgres -d map_app -f ../database/migration_002_fix_users_id_generation.sql
```

**Important:** Make sure to run migration_002 to fix the users ID auto-generation issue.

5. Start the server:
```bash
# Development mode with nodemon
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:3000`

### Health Check

```bash
curl http://localhost:3000/health
```

## API Documentation

### Base URL
```
http://localhost:3000/api
```

### Response Format

All responses follow this format:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "errors": [ ... ] // Optional validation errors
}
```

---

## Authentication

### 1. Sign Up

**Endpoint:** `POST /api/auth/signup`

**Description:** Register a new user

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "role": "user" // Optional: "user" or "admin" (default: "user")
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user",
      "createdAt": "2024-01-01T00:00:00.000Z"
    },
    "token": "jwt-token-here"
  }
}
```

### 2. Login

**Endpoint:** `POST /api/auth/login`

**Description:** Login and receive JWT token

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user"
    },
    "token": "jwt-token-here"
  }
}
```

### 3. Get Profile

**Endpoint:** `GET /api/auth/me`

**Description:** Get current user profile

**Headers:**
```
Authorization: Bearer {token}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "user",
    "pointsContributed": 10,
    "polygonesContributed": 5,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "lastLogin": "2024-01-01T00:00:00.000Z"
  }
}
```

### 4. Verify Token

**Endpoint:** `GET /api/auth/verify`

**Description:** Verify if JWT token is valid

**Headers:**
```
Authorization: Bearer {token}
```

**Response:** `200 OK`

---

## Users

All user endpoints require authentication.

### 1. Get All Users (Admin Only)

**Endpoint:** `GET /api/users`

**Description:** Get paginated list of users

**Headers:**
```
Authorization: Bearer {admin-token}
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10, max: 100)
- `role` (optional): Filter by role ("user" or "admin")
- `search` (optional): Search by email or name

**Example:** `GET /api/users?page=1&limit=10&role=user&search=john`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "uuid",
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe",
        "role": "user",
        "pointsContributed": 10,
        "polygonesContributed": 5,
        "createdAt": "2024-01-01T00:00:00.000Z",
        "lastLogin": "2024-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 100,
      "page": 1,
      "limit": 10,
      "totalPages": 10
    }
  }
}
```

### 2. Get User By ID

**Endpoint:** `GET /api/users/:id`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:** `200 OK`

### 3. Update User

**Endpoint:** `PUT /api/users/:id`

**Description:** Update user (own account or admin)

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "newmail@example.com",
  "password": "newpassword123", // Optional
  "role": "admin" // Only admin can change roles
}
```

**Response:** `200 OK`

### 4. Delete User (Admin Only)

**Endpoint:** `DELETE /api/users/:id`

**Headers:**
```
Authorization: Bearer {admin-token}
```

**Response:** `200 OK`

### 5. Get User Statistics

**Endpoint:** `GET /api/users/:id/stats`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "userId": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "statistics": {
      "pointsContributed": 10,
      "polygonesContributed": 5,
      "projectsCount": 3
    }
  }
}
```

---

## Polygons

All polygon endpoints require authentication.

### 1. Create Polygon

**Endpoint:** `POST /api/polygons`

**Description:** Create a new polygon with PostGIS geometry

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "coordinates": [
    [35.8617, -5.4783],
    [35.8627, -5.4793],
    [35.8637, -5.4803]
  ],
  "cropType": "Wheat",
  "area": 1500.50,
  "perimeter": 200.25,
  "notes": "Good quality soil",
  "projectId": "project-uuid", // Optional
  "images": ["url1", "url2"] // Optional
}
```

**Response:** `201 Created`

### 2. Get All Polygons

**Endpoint:** `GET /api/polygons`

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page
- `cropType` (optional): Filter by crop type
- `projectId` (optional): Filter by project
- `userId` (optional): Filter by user
- `minArea` (optional): Minimum area
- `maxArea` (optional): Maximum area

**Example:** `GET /api/polygons?cropType=Wheat&page=1&limit=20`

**Response:** `200 OK`

### 3. Get Polygon By ID

**Endpoint:** `GET /api/polygons/:id`

**Response:** `200 OK`

### 4. Update Polygon

**Endpoint:** `PUT /api/polygons/:id`

**Request Body:**
```json
{
  "cropType": "Corn",
  "notes": "Updated notes",
  "images": ["url1", "url2"]
}
```

**Response:** `200 OK`

### 5. Delete Polygon

**Endpoint:** `DELETE /api/polygons/:id`

**Response:** `200 OK`

### 6. Get Polygons Within Bounds

**Endpoint:** `POST /api/polygons/within-bounds`

**Description:** Get all polygons within map bounds (PostGIS spatial query)

**Request Body:**
```json
{
  "northEast": {
    "lat": 35.8700,
    "lng": -5.4700
  },
  "southWest": {
    "lat": 35.8600,
    "lng": -5.4800
  }
}
```

**Response:** `200 OK`

---

## Points

All point endpoints require authentication.

### 1. Create Point

**Endpoint:** `POST /api/points`

**Request Body:**
```json
{
  "latitude": 35.8617,
  "longitude": -5.4783,
  "cropType": "Tomato",
  "notes": "High yield area",
  "projectId": "project-uuid", // Optional
  "images": ["url1", "url2"] // Optional
}
```

**Response:** `201 Created`

### 2. Get All Points

**Endpoint:** `GET /api/points`

**Query Parameters:**
- `page`, `limit`, `cropType`, `projectId`, `userId`

**Response:** `200 OK`

### 3. Get Point By ID

**Endpoint:** `GET /api/points/:id`

**Response:** `200 OK`

### 4. Update Point

**Endpoint:** `PUT /api/points/:id`

**Response:** `200 OK`

### 5. Delete Point

**Endpoint:** `DELETE /api/points/:id`

**Response:** `200 OK`

### 6. Get Points Within Bounds

**Endpoint:** `POST /api/points/within-bounds`

**Request Body:**
```json
{
  "northEast": {
    "lat": 35.8700,
    "lng": -5.4700
  },
  "southWest": {
    "lat": 35.8600,
    "lng": -5.4800
  }
}
```

**Response:** `200 OK`

---

## Projects

All project endpoints require authentication.

### 1. Create Project

**Endpoint:** `POST /api/projects`

**Request Body:**
```json
{
  "name": "Agricultural Survey 2024",
  "description": "Mapping wheat fields in northern region",
  "startDate": "2024-01-01",
  "endDate": "2024-12-31",
  "targetArea": 10000.00,
  "status": "active" // "active", "completed", or "cancelled"
}
```

**Response:** `201 Created`

### 2. Get All Projects

**Endpoint:** `GET /api/projects`

**Query Parameters:**
- `page`, `limit`, `status`, `search`

**Response:** `200 OK`

### 3. Get Project By ID

**Endpoint:** `GET /api/projects/:id`

**Response:** `200 OK` (includes contributors list)

### 4. Update Project

**Endpoint:** `PUT /api/projects/:id`

**Note:** Only project creator or admin can update

**Response:** `200 OK`

### 5. Delete Project

**Endpoint:** `DELETE /api/projects/:id`

**Note:** Only project creator or admin can delete

**Response:** `200 OK`

### 6. Add Contributor

**Endpoint:** `POST /api/projects/:id/contributors`

**Request Body:**
```json
{
  "userId": "user-uuid"
}
```

**Response:** `201 Created`

### 7. Remove Contributor

**Endpoint:** `DELETE /api/projects/:id/contributors/:userId`

**Response:** `200 OK`

---

## Error Handling

### HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Validation error or invalid input
- `401 Unauthorized` - Authentication required or invalid token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `500 Internal Server Error` - Server error

### Common Error Responses

**Validation Error:**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Please provide a valid email"
    }
  ]
}
```

**Authentication Error:**
```json
{
  "success": false,
  "message": "Access denied. No token provided."
}
```

**Authorization Error:**
```json
{
  "success": false,
  "message": "Access denied. Insufficient permissions."
}
```

---

## Development

### Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js      # PostgreSQL connection pool
│   │   └── config.js        # Environment configuration
│   ├── middleware/
│   │   ├── auth.js          # JWT authentication & authorization
│   │   ├── errorHandler.js  # Global error handling
│   │   └── validator.js     # Validation middleware
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── userController.js
│   │   ├── polygonController.js
│   │   ├── pointController.js
│   │   └── projectController.js
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── userRoutes.js
│   │   ├── polygonRoutes.js
│   │   ├── pointRoutes.js
│   │   └── projectRoutes.js
│   └── utils/               # Utility functions
├── .env                     # Environment variables
├── .env.example             # Environment template
├── package.json
├── server.js                # Main entry point
└── README.md
```

### Scripts

```bash
# Start server in production
npm start

# Start server in development (with nodemon)
npm run dev
```

### Security Best Practices

1. **Change JWT Secret** - Always use a strong, random JWT secret in production
2. **Use HTTPS** - Enable HTTPS in production
3. **Rate Limiting** - Consider adding rate limiting middleware
4. **Environment Variables** - Never commit `.env` file to version control
5. **Database Security** - Use strong database passwords and restrict access
6. **Input Validation** - All inputs are validated using express-validator
7. **Password Hashing** - Passwords are hashed using bcrypt with 10 rounds

### Database Schema

The API uses PostgreSQL with PostGIS extension. Make sure the database schema is created:

```bash
psql -U postgres -d map_app -f ../database/schema.sql
```

---

## License

MIT

## Support

For issues and questions, please open an issue on the project repository.

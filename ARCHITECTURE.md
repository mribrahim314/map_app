# Map App - Architecture Documentation

## Overview

This document describes the split architecture of the Map Application, which now consists of a **separate backend API** and **Flutter frontend**.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App (Frontend)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  UI Screens  │  │   BLoC/State │  │  API Client Service  │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                    HTTP/REST (JSON over HTTPS)
                               │
┌──────────────────────────────┴──────────────────────────────────┐
│                    Node.js Backend (API Server)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   Express    │  │  JWT Auth    │  │  Route Controllers   │  │
│  │  Middleware  │  │  Middleware  │  │  (Business Logic)    │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                         SQL Connection
                               │
┌──────────────────────────────┴──────────────────────────────────┐
│                PostgreSQL Database + PostGIS                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  users   │  │ polygons │  │  points  │  │   projects   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘

External Services:
  └─→ Supabase (Image Storage)
```

## Components

### 1. Flutter Frontend (`/lib`)

**Technology Stack:**
- Flutter/Dart
- BLoC for state management
- HTTP package for API calls
- Flutter Secure Storage for JWT tokens

**Key Files:**
- `/lib/core/networking/api_client.dart` - HTTP client wrapper
- `/lib/core/services/auth_service.dart` - Authentication service using JWT
- `/lib/core/models/` - Data models
- `/lib/features/` - Feature-specific UI screens

**Responsibilities:**
- User interface and user experience
- Client-side state management
- JWT token storage
- Offline caching with Hive
- Image uploads to Supabase

### 2. Node.js Backend (`/backend`)

**Technology Stack:**
- Node.js + Express.js
- PostgreSQL with node-postgres (pg)
- JWT for authentication
- bcrypt for password hashing
- express-validator for input validation

**Key Files:**
- `/backend/server.js` - Main entry point
- `/backend/src/config/database.js` - Database connection pool
- `/backend/src/middleware/auth.js` - JWT authentication
- `/backend/src/controllers/` - Business logic
- `/backend/src/routes/` - API endpoints

**Responsibilities:**
- RESTful API endpoints
- Business logic and validation
- Database operations
- Authentication and authorization
- Security and rate limiting

### 3. PostgreSQL Database (`/database`)

**Technology Stack:**
- PostgreSQL 12+
- PostGIS extension for spatial data

**Schema:**
- `users` - User accounts and authentication
- `polygones` - Agricultural polygons with geometry
- `points` - Individual crop points with geometry
- `projects` - Data collection campaigns
- `project_contributors` - Many-to-many relationship

## Authentication Flow

### Old Architecture (Direct Database)
```
Flutter App ──(SQL queries)──> PostgreSQL
     │
     └──(bcrypt)──> Password Hashing in App
```

### New Architecture (API with JWT)
```
1. Login/Signup:
   Flutter App ──(email/password)──> Backend API
                                          │
                                    (bcrypt verify)
                                          │
                                    (generate JWT)
                                          │
   Flutter App <──(JWT token)────── Backend API

2. Authenticated Requests:
   Flutter App ──(Bearer JWT token)──> Backend API
                                          │
                                    (verify JWT)
                                          │
                                    (authorize)
                                          │
   Flutter App <───(JSON response)───── Backend API ──> PostgreSQL
```

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user profile
- `GET /api/auth/verify` - Verify JWT token

### Users
- `GET /api/users` - Get all users (admin)
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user (admin)
- `GET /api/users/:id/stats` - Get user statistics

### Polygons
- `POST /api/polygons` - Create polygon
- `GET /api/polygons` - Get all polygons (with filters)
- `GET /api/polygons/:id` - Get polygon by ID
- `PUT /api/polygons/:id` - Update polygon
- `DELETE /api/polygons/:id` - Delete polygon
- `POST /api/polygons/within-bounds` - Get polygons within map bounds

### Points
- `POST /api/points` - Create point
- `GET /api/points` - Get all points (with filters)
- `GET /api/points/:id` - Get point by ID
- `PUT /api/points/:id` - Update point
- `DELETE /api/points/:id` - Delete point
- `POST /api/points/within-bounds` - Get points within map bounds

### Projects
- `POST /api/projects` - Create project
- `GET /api/projects` - Get all projects
- `GET /api/projects/:id` - Get project by ID
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/projects/:id/contributors` - Add contributor
- `DELETE /api/projects/:id/contributors/:userId` - Remove contributor

## Setup Instructions

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Ensure PostgreSQL database exists:**
   ```bash
   psql -U postgres -d map_app -f ../database/schema.sql
   ```

5. **Start backend server:**
   ```bash
   # Development mode (with auto-reload)
   npm run dev

   # Production mode
   npm start
   ```

   The API will be available at `http://localhost:3000`

### Frontend Setup

1. **Navigate to project root:**
   ```bash
   cd /path/to/map_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure environment:**
   ```bash
   # The .env file should already have API_BASE_URL set
   # Verify it points to your backend:
   API_BASE_URL=http://localhost:3000/api
   ```

4. **Run Flutter app:**
   ```bash
   flutter run
   ```

## Development Workflow

### Starting Both Services

**Terminal 1 (Backend):**
```bash
cd backend
npm run dev
```

**Terminal 2 (Frontend):**
```bash
flutter run
```

### Making Changes

**Backend Changes:**
- Edit files in `/backend/src/`
- nodemon will auto-reload the server

**Frontend Changes:**
- Edit files in `/lib/`
- Hot reload: Press `r` in Flutter console
- Hot restart: Press `R` in Flutter console

## Security Improvements

### What Changed?

| Aspect | Old (Direct DB) | New (API Architecture) |
|--------|-----------------|------------------------|
| **Database Access** | Direct from Flutter app | Only backend can access |
| **Credentials** | Stored in Flutter app | Only in backend .env |
| **Authentication** | Custom bcrypt in app | JWT tokens |
| **Authorization** | Client-side checks | Server-side enforcement |
| **SQL Injection** | Risk present | Protected by parameterized queries |
| **Rate Limiting** | None | Can be added to API |
| **HTTPS** | N/A | Required for production |

### Security Best Practices

1. **Never commit `.env` files** - They contain secrets
2. **Use strong JWT secrets** - Change from default
3. **Enable HTTPS in production** - Encrypt all traffic
4. **Set CORS properly** - Restrict to your domain
5. **Keep dependencies updated** - Run `npm audit` regularly
6. **Use strong database passwords** - Never use defaults
7. **Backup database regularly** - Prevent data loss

## Deployment

### Backend Deployment

**Recommended Platforms:**
- Heroku
- DigitalOcean App Platform
- AWS Elastic Beanstalk
- Railway
- Render

**Steps:**
1. Push code to Git repository
2. Connect to deployment platform
3. Set environment variables
4. Deploy

### Frontend Deployment

**Mobile:**
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

**Web:**
```bash
flutter build web
```

### Database Deployment

**Recommended Platforms:**
- AWS RDS PostgreSQL
- DigitalOcean Managed Databases
- Heroku Postgres
- Supabase PostgreSQL

**Requirements:**
- PostgreSQL 12+
- PostGIS extension enabled

## Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill
```

**Database connection failed:**
- Verify PostgreSQL is running
- Check credentials in `.env`
- Ensure database exists

### Frontend Issues

**API connection refused:**
- Ensure backend is running
- Check `API_BASE_URL` in `.env`
- For Android emulator, use `http://10.0.2.2:3000/api`

**JWT token expired:**
- User will need to login again
- Tokens expire after 7 days by default

## Migration Guide

### From Old to New Architecture

**What was removed:**
- ✗ `postgres` package from Flutter
- ✗ `bcrypt` package from Flutter
- ✗ Direct database credentials in Flutter `.env`
- ✗ `DatabaseService` class
- ✗ SQL queries in repositories

**What was added:**
- ✓ Node.js Express backend
- ✓ JWT authentication
- ✓ RESTful API endpoints
- ✓ API client in Flutter
- ✓ Token-based authentication

**Files Modified:**
- `lib/core/services/auth_service.dart` - Now uses API client
- `pubspec.yaml` - Removed postgres dependency
- `.env` - Changed from DB config to API config

**Files Created:**
- `backend/` - Entire backend directory
- `lib/core/networking/api_client.dart` - HTTP client wrapper

## Performance Considerations

### Caching Strategy

**Frontend:**
- Hive for offline data storage
- Secure storage for JWT tokens
- In-memory state with BLoC

**Backend:**
- PostgreSQL connection pooling
- Can add Redis for caching (future)

### Optimization Tips

1. **Backend:**
   - Use database indexes
   - Enable gzip compression
   - Add pagination to all list endpoints
   - Cache frequently accessed data

2. **Frontend:**
   - Lazy load data
   - Implement infinite scroll
   - Cache images
   - Debounce API calls

## Monitoring and Logging

### Backend Logging
- Morgan for HTTP request logging
- Console logs for debugging
- Consider adding Winston for production

### Frontend Logging
- Console prints for development
- Consider crash reporting (Sentry, Crashlytics)

## Future Enhancements

1. **API Features:**
   - Rate limiting
   - API versioning
   - WebSocket support for real-time updates
   - GraphQL as alternative to REST

2. **Security:**
   - Two-factor authentication
   - OAuth integration (Google, Facebook)
   - API key management
   - CAPTCHA for signup

3. **Performance:**
   - Redis caching
   - CDN for static assets
   - Database read replicas
   - API response compression

4. **DevOps:**
   - Docker containerization
   - CI/CD pipeline
   - Automated testing
   - Health monitoring

## Support

For issues related to:
- **Backend API:** See `/backend/README.md`
- **Flutter App:** See main `/README.md`
- **Database:** See `/database/schema.sql`

## License

MIT

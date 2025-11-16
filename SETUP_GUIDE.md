# Complete Setup Guide - Map App

This guide will help you set up and run the Map Application with its split backend and frontend architecture.

## Prerequisites

Before you begin, ensure you have the following installed:

- **PostgreSQL 12+** with PostGIS extension
- **Node.js 14+** and npm
- **Flutter SDK 3.8+**
- **Git**

---

## 📦 Part 1: Database Setup

### 1.1 Create PostgreSQL Database

```bash
# Login to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE map_app;

# Exit psql
\q
```

### 1.2 Run Initial Schema

```bash
# Run the initial schema
psql -U postgres -d map_app -f database/schema.sql
```

### 1.3 Run Migration (IMPORTANT!)

The migration aligns the database schema with the new API structure:

```bash
# Run the migration to add new columns
psql -U postgres -d map_app -f database/migration_001_align_schema.sql
```

**What this migration does:**
- Adds `first_name`, `last_name`, `last_login` to users table
- Adds `points_contributed`, `polygones_contributed` to users table
- Updates role values from 'normal' to 'user'
- Adds `crop_type`, `area`, `perimeter`, `notes`, `images` to polygones table
- Adds `crop_type`, `notes`, `images` to points table
- Adds `target_area`, `status` to projects table
- Renames `added_at` to `joined_at` in project_contributors
- Updates views and indexes

### 1.4 Verify Database Setup

```bash
# Check if PostGIS is enabled
psql -U postgres -d map_app -c "SELECT PostGIS_version();"

# Check tables
psql -U postgres -d map_app -c "\dt"

# You should see: users, polygones, points, projects, project_contributors
```

---

## 🔧 Part 2: Backend API Setup

### 2.1 Install Dependencies

```bash
cd backend
npm install
```

### 2.2 Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env with your settings
nano .env
```

Update the following in `backend/.env`:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=map_app
DB_USER=postgres
DB_PASSWORD=your_postgres_password_here

# JWT Configuration - IMPORTANT: Change this!
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long
JWT_EXPIRES_IN=7d

# CORS Configuration
CORS_ORIGIN=*
```

**Security Note:** Change `JWT_SECRET` to a strong random string (at least 32 characters) before deploying to production.

### 2.3 Start Backend Server

```bash
# Development mode (auto-reload on changes)
npm run dev

# OR Production mode
npm start
```

You should see:
```
==========================================
🚀 Server running on port 3000
📝 Environment: development
🔗 API URL: http://localhost:3000/api
💚 Health check: http://localhost:3000/health
==========================================
✅ Database connected successfully
```

### 2.4 Test Backend API

Open a new terminal and test:

```bash
# Health check
curl http://localhost:3000/health

# Expected response:
# {"success":true,"message":"Server is running","timestamp":"...","environment":"development"}
```

---

## 📱 Part 3: Flutter Frontend Setup

### 3.1 Install Dependencies

```bash
# Navigate to project root
cd ..  # (from backend directory)

# Get Flutter dependencies
flutter pub get
```

### 3.2 Configure Environment

The `.env` file should already be configured from the previous setup. Verify it contains:

```env
# Backend API Configuration
API_BASE_URL=http://localhost:3000/api

# Supabase Configuration (for image storage)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

**For Android Emulator:** If you're using Android emulator, change `localhost` to `10.0.2.2`:
```env
API_BASE_URL=http://10.0.2.2:3000/api
```

**For iOS Simulator:** Use `localhost`:
```env
API_BASE_URL=http://localhost:3000/api
```

**For Physical Device:** Use your computer's IP address:
```env
API_BASE_URL=http://192.168.1.XXX:3000/api
```

### 3.3 Run Flutter App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# OR just run (will prompt for device selection)
flutter run
```

---

## 🎯 Part 4: First-Time Usage

### 4.1 Create Admin User

You can create an admin user directly via the API:

```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "AdminPassword123!",
    "firstName": "Admin",
    "lastName": "User",
    "role": "admin"
  }'
```

Or via the Flutter app:
1. Open the app
2. Go to Sign Up screen
3. Enter admin credentials
4. You can update the role to admin manually in the database:

```bash
psql -U postgres -d map_app
UPDATE users SET role = 'admin' WHERE email = 'admin@example.com';
\q
```

### 4.2 Test Authentication

**Via App:**
1. Login with the admin user you created
2. You should be redirected to the main screen

**Via API:**
```bash
# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "AdminPassword123!"
  }'

# Save the token from the response
TOKEN="<paste-token-here>"

# Test authenticated endpoint
curl http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🏃 Part 5: Running Both Services

You need to run both backend and frontend simultaneously.

### Option 1: Two Terminals

**Terminal 1 (Backend):**
```bash
cd backend
npm run dev
```

**Terminal 2 (Frontend):**
```bash
flutter run
```

### Option 2: Using tmux (Linux/Mac)

```bash
# Start tmux session
tmux new -s mapapp

# In first pane, start backend
cd backend && npm run dev

# Split terminal (Ctrl+B, then ")
# In second pane, start frontend
flutter run

# Navigate between panes: Ctrl+B, then arrow keys
# Detach from session: Ctrl+B, then D
# Reattach: tmux attach -t mapapp
```

---

## 🧪 Part 6: Testing

### 6.1 Test Backend Endpoints

See `backend/README.md` for complete API documentation.

**Key endpoints to test:**

```bash
# Authentication
POST   /api/auth/signup
POST   /api/auth/login
GET    /api/auth/me
GET    /api/auth/verify

# Users (requires auth)
GET    /api/users
GET    /api/users/:id
PUT    /api/users/:id
DELETE /api/users/:id

# Polygons (requires auth)
POST   /api/polygons
GET    /api/polygons
GET    /api/polygons/:id
PUT    /api/polygons/:id
DELETE /api/polygons/:id

# Points (requires auth)
POST   /api/points
GET    /api/points
GET    /api/points/:id
PUT    /api/points/:id
DELETE /api/points/:id

# Projects (requires auth)
POST   /api/projects
GET    /api/projects
GET    /api/projects/:id
PUT    /api/projects/:id
DELETE /api/projects/:id
```

### 6.2 Test Flutter App

1. **Sign Up** - Create a new user account
2. **Login** - Login with the created account
3. **View Map** - Check if map loads correctly
4. **Add Point** - Create a new point on the map
5. **Add Polygon** - Draw a polygon on the map
6. **View Profile** - Check user profile and statistics
7. **Logout** - Logout and verify token is cleared

---

## 🐛 Troubleshooting

### Backend Issues

**Port 3000 already in use:**
```bash
# Find process using port 3000
lsof -ti:3000

# Kill the process
lsof -ti:3000 | xargs kill
```

**Database connection refused:**
```bash
# Check if PostgreSQL is running
sudo service postgresql status

# Start PostgreSQL
sudo service postgresql start

# OR on Mac
brew services start postgresql
```

**FATAL: password authentication failed:**
- Update `DB_PASSWORD` in `backend/.env`
- Or reset PostgreSQL password:
```bash
sudo -u postgres psql
ALTER USER postgres PASSWORD 'newpassword';
\q
```

### Frontend Issues

**API connection refused:**
- Ensure backend is running on port 3000
- Check `API_BASE_URL` in `.env`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical devices, use your computer's IP address

**Flutter dependencies error:**
```bash
flutter clean
flutter pub get
```

**JWT token expired:**
- User needs to login again
- Tokens expire after 7 days by default
- You can change this in `backend/src/config/config.js`

**Module 'postgres' not found:**
- This is expected - we removed the postgres package
- Run `flutter pub get` to refresh dependencies

### Database Issues

**PostGIS not found:**
```bash
# Install PostGIS
sudo apt-get install postgresql-postgis  # Ubuntu/Debian
brew install postgis                     # Mac

# Enable in database
psql -U postgres -d map_app
CREATE EXTENSION postgis;
\q
```

**Migration already run:**
- The migration is idempotent (safe to run multiple times)
- If you see "column already exists" errors, it's safe to ignore

**Old data not showing:**
- Run the migration to populate new columns from old columns
- The migration copies `type` → `crop_type`, `message` → `notes`, etc.

---

## 📊 Database Management

### Backup Database

```bash
# Backup entire database
pg_dump -U postgres map_app > backup_$(date +%Y%m%d).sql

# Backup only schema
pg_dump -U postgres -s map_app > schema_backup.sql

# Backup only data
pg_dump -U postgres -a map_app > data_backup.sql
```

### Restore Database

```bash
# Restore from backup
psql -U postgres -d map_app < backup_20240101.sql
```

### View Database Statistics

```bash
# Connect to database
psql -U postgres -d map_app

# View user statistics
SELECT * FROM user_stats;

# View project statistics
SELECT * FROM project_stats;

# Count records
SELECT
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM polygones) as polygons,
  (SELECT COUNT(*) FROM points) as points,
  (SELECT COUNT(*) FROM projects) as projects;

# Exit
\q
```

---

## 🚀 Deployment

See `ARCHITECTURE.md` for deployment instructions.

**Quick deployment checklist:**

### Backend Deployment
- [ ] Change `JWT_SECRET` to strong random string
- [ ] Set `NODE_ENV=production`
- [ ] Use managed PostgreSQL database (AWS RDS, DigitalOcean, etc.)
- [ ] Enable SSL/TLS for database connection
- [ ] Set proper `CORS_ORIGIN` (not `*`)
- [ ] Deploy to server (Heroku, Railway, DigitalOcean, etc.)

### Frontend Deployment
- [ ] Update `API_BASE_URL` to production backend URL
- [ ] Build for release: `flutter build apk` or `flutter build ios`
- [ ] Upload to Google Play / App Store

### Database Deployment
- [ ] Use managed PostgreSQL with PostGIS
- [ ] Set up automated backups
- [ ] Configure firewall to only allow backend access
- [ ] Enable SSL connections

---

## 📚 Additional Resources

- **API Documentation:** `backend/README.md`
- **Architecture Overview:** `ARCHITECTURE.md`
- **Database Schema:** `database/schema.sql`
- **Migration Script:** `database/migration_001_align_schema.sql`

---

## 🆘 Getting Help

If you encounter issues:

1. Check this guide thoroughly
2. Review error messages in:
   - Backend console
   - Flutter console
   - Database logs
3. Verify all environment variables are set correctly
4. Ensure all services are running (PostgreSQL, Backend, Frontend)
5. Check API documentation in `backend/README.md`

---

## ✅ Quick Start Checklist

- [ ] PostgreSQL installed and running
- [ ] Database `map_app` created
- [ ] Initial schema applied
- [ ] **Migration script applied** ⚠️ IMPORTANT
- [ ] PostGIS extension enabled
- [ ] Backend dependencies installed (`npm install`)
- [ ] Backend `.env` configured
- [ ] Backend server running on port 3000
- [ ] Health check passes: `curl http://localhost:3000/health`
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Flutter `.env` configured with `API_BASE_URL`
- [ ] Flutter app running on device/emulator
- [ ] Admin user created
- [ ] Login successful
- [ ] Map loads correctly

---

**Congratulations! Your Map App is now running with a secure backend/frontend architecture! 🎉**

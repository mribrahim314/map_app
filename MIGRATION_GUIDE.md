# Firebase to PostgreSQL/PostGIS Migration Guide

## Overview

This document outlines the migration of the agricultural mapping application from Firebase (Firestore + Firebase Auth) to PostgreSQL with PostGIS extension.

## What Has Changed

### 1. Database System
- **Before**: Firebase Firestore (NoSQL cloud database)
- **After**: PostgreSQL with PostGIS extension (SQL database with geospatial support)

### 2. Authentication
- **Before**: Firebase Authentication
- **After**: Custom authentication using PostgreSQL with password hashing (SHA256)

### 3. Data Models
- **Before**: Firebase documents with GeoPoint arrays
- **After**: PostgreSQL tables with PostGIS geometry columns (POINT and POLYGON types)

## New Directory Structure

```
lib/
├── core/
│   ├── database/
│   │   ├── database_service.dart       # PostgreSQL connection service
│   │   └── db_config.dart              # Database configuration
│   ├── models/
│   │   ├── user_model.dart             # User data model
│   │   ├── polygon_model.dart          # Polygon data model
│   │   └── point_model.dart            # Point data model
│   ├── repositories/
│   │   ├── user_repository.dart        # User database operations
│   │   ├── polygon_repository.dart     # Polygon database operations
│   │   └── point_repository.dart       # Point database operations
│   └── services/
│       └── auth_service.dart           # Authentication service
database/
└── schema.sql                          # PostgreSQL database schema
```

## Database Setup

### Prerequisites

1. Install PostgreSQL (version 12 or higher recommended)
2. Install PostGIS extension

### macOS
```bash
brew install postgresql postgis
brew services start postgresql
```

### Ubuntu/Debian
```bash
sudo apt-get install postgresql postgresql-contrib postgis
sudo systemctl start postgresql
```

### Windows
Download and install from [PostgreSQL official website](https://www.postgresql.org/download/windows/)

### Create Database

```bash
# Connect to PostgreSQL
psql postgres

# Create database
CREATE DATABASE map_app;

# Connect to the database
\c map_app

# Run the schema file
\i database/schema.sql
```

Or use the SQL file directly:
```bash
psql -U postgres -d map_app -f database/schema.sql
```

## Configuration

### Update Database Credentials

Edit `lib/core/database/db_config.dart`:

```dart
class DbConfig {
  static const String host = 'localhost';      // Your PostgreSQL host
  static const int port = 5432;                // PostgreSQL port
  static const String databaseName = 'map_app'; // Database name
  static const String username = 'postgres';    // PostgreSQL username
  static const String password = 'your_password'; // PostgreSQL password
}
```

**For production**, use environment variables or secure storage instead of hardcoded values.

## Migration Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Set Up PostgreSQL Database

Run the schema file as shown above to create tables, indexes, and functions.

### 3. Migrate Existing Data (Optional)

If you have existing Firebase data to migrate:

#### Export from Firebase
1. Go to Firebase Console
2. Navigate to Firestore
3. Export collections: `users`, `polygones`, `points`

#### Import to PostgreSQL
Create a migration script to:
1. Read Firebase JSON exports
2. Convert GeoPoint arrays to PostGIS geometry
3. Insert into PostgreSQL tables

Example conversion:
```dart
// Firebase GeoPoint array
[GeoPoint(33.888, 35.495), GeoPoint(33.889, 35.496), ...]

// PostgreSQL PostGIS POLYGON
POLYGON((35.495 33.888, 35.496 33.889, ...))
// Note: PostGIS uses (longitude, latitude) order
```

### 4. Test the Application

```bash
flutter run
```

## Key Code Changes

### Authentication

**Before (Firebase Auth):**
```dart
final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
```

**After (PostgreSQL):**
```dart
final authService = Provider.of<AuthService>(context, listen: false);
final user = await authService.signUp(
  email: email,
  password: password,
  role: 'normal',
);
```

### Data Storage

**Before (Firestore):**
```dart
await FirebaseFirestore.instance.collection('polygones').add({
  "coordinates": [GeoPoint(lat, lng), ...],
  "Type": type,
  // ...
});
```

**After (PostgreSQL):**
```dart
final polygonRepo = PolygonRepository();
final polygon = PolygonModel(
  coordinates: [LatLng(lat, lng), ...],
  type: type,
  // ...
);
await polygonRepo.createPolygon(polygon);
```

### Data Retrieval

**Before (Firestore):**
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('polygones')
  .where('Type', isEqualTo: type)
  .get();
```

**After (PostgreSQL):**
```dart
final polygonRepo = PolygonRepository();
final polygons = await polygonRepo.getPolygonsByType(type: type);
```

## Database Schema

### Users Table
- `id`: VARCHAR (primary key)
- `email`: VARCHAR (unique)
- `password_hash`: VARCHAR (SHA256 hash)
- `role`: VARCHAR (normal|admin|moderator)
- `contribution_count`: INTEGER
- `contribution_request_sent`: BOOLEAN
- `created_at`: TIMESTAMP
- `updated_at`: TIMESTAMP

### Polygones Table
- `id`: SERIAL (primary key)
- `district`: VARCHAR
- `gouvernante`: VARCHAR
- `type`: VARCHAR (crop type)
- `geometry`: GEOMETRY(POLYGON, 4326) - PostGIS spatial column
- `message`: TEXT
- `image_url`: TEXT
- `user_id`: VARCHAR (foreign key → users.id)
- `is_adopted`: BOOLEAN
- `date`: TIMESTAMP
- `created_at`: TIMESTAMP
- `updated_at`: TIMESTAMP

### Points Table
- `id`: SERIAL (primary key)
- `district`: VARCHAR
- `gouvernante`: VARCHAR
- `type`: VARCHAR (crop type)
- `geometry`: GEOMETRY(POINT, 4326) - PostGIS spatial column
- `message`: TEXT
- `image_url`: TEXT
- `user_id`: VARCHAR (foreign key → users.id)
- `is_adopted`: BOOLEAN
- `date`: TIMESTAMP
- `parcel_size`: VARCHAR (Small|Medium|Large)
- `created_at`: TIMESTAMP
- `updated_at`: TIMESTAMP

## PostGIS Features

### Spatial Indexes
All geometry columns have GIST indexes for fast spatial queries:
```sql
CREATE INDEX idx_polygones_geometry ON polygones USING GIST(geometry);
CREATE INDEX idx_points_geometry ON points USING GIST(geometry);
```

### Spatial Functions
The schema includes helper functions:

1. **get_polygones_in_bbox()** - Get polygons within a bounding box
2. **get_points_in_bbox()** - Get points within a bounding box
3. **increment_contribution_count()** - Increment user contribution count

### Spatial Queries
```sql
-- Find polygons intersecting a bounding box
SELECT * FROM get_polygones_in_bbox(35.0, 33.0, 36.0, 34.0, 'زيتون', TRUE);

-- Calculate area of a polygon (in square meters)
SELECT ST_Area(geometry::geography) FROM polygones WHERE id = 1;

-- Find distance between two points (in meters)
SELECT ST_Distance(
  (SELECT geometry FROM points WHERE id = 1)::geography,
  (SELECT geometry FROM points WHERE id = 2)::geography
);
```

## Remaining Tasks

The following files still need to be updated to complete the migration:

### High Priority
1. **User Profile Screen** (`lib/features/user_profile/user_profile_screen.dart`)
   - Replace Firebase Auth with AuthService
   - Update user data retrieval

2. **Admin Screen** (`lib/features/admin_screen/admin_screen.dart`)
   - Replace Firestore queries with UserRepository
   - Update user listing and management

3. **GeoJSON Export** (`lib/features/admin_screen/exprot_service.dart`)
   - Update to use PostgreSQL repositories
   - PostGIS already supports GeoJSON with `ST_AsGeoJSON()`

4. **Polygon/Point Repository** (`lib/core/networking/polygone_and_points_repo.dart`)
   - Update all Firestore queries to use new repositories

5. **Offline Sync** (`lib/core/models/pending_submission.dart`)
   - Update `sendPendingSubmissions()` to use PostgreSQL repositories

### Medium Priority
6. **Edit Screen** (`lib/features/admin_user_screen/edit_screen.dart`)
7. **Delete Data** (`lib/features/admin_user_screen/services/delete_data.dart`)
8. **Build List** (`lib/features/admin_user_screen/services/build_list.dart`)

### Optional
9. Remove Firebase dependencies from `pubspec.yaml`
10. Remove `firebase_options.dart` and `google-services.json`
11. Update Android/iOS configuration to remove Firebase SDK

## Performance Considerations

### Advantages of PostgreSQL/PostGIS
1. **Better Spatial Queries**: PostGIS offers advanced geospatial functions
2. **ACID Compliance**: Full transactional support
3. **Complex Queries**: JOIN operations, aggregations, etc.
4. **Data Integrity**: Foreign keys, constraints, triggers
5. **Cost**: Self-hosted, no per-operation charges

### Optimizations
1. Use connection pooling (already implemented in DatabaseService)
2. Spatial indexes are created automatically
3. Use prepared statements (handled by postgres package)
4. Consider materialized views for complex queries

## Real-time Features

### Firebase vs PostgreSQL
- **Firebase**: Built-in real-time listeners (snapshots)
- **PostgreSQL**: Use LISTEN/NOTIFY or polling

### Implementing Real-time Updates (Optional)
```sql
-- Create notification trigger
CREATE OR REPLACE FUNCTION notify_users_change()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('users_changed', row_to_json(NEW)::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_change_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION notify_users_change();
```

## Security Notes

### Password Storage
- Passwords are hashed using SHA256
- **Recommendation**: Upgrade to bcrypt or Argon2 for production

### Database Access
- Never expose database credentials in client apps
- Use connection pooling with limited connections
- Implement proper user permissions in PostgreSQL

### Future Improvements
1. Implement JWT-based authentication
2. Add refresh tokens for session management
3. Use bcrypt/Argon2 for password hashing
4. Implement API layer (REST or GraphQL) between app and database
5. Add rate limiting and request validation

## Troubleshooting

### Database Connection Failed
```
Error: Database connection failed
```
**Solution**:
- Check PostgreSQL is running: `pg_isready`
- Verify credentials in `db_config.dart`
- Check firewall settings
- Ensure PostgreSQL is listening on the correct port

### PostGIS Extension Not Found
```
Error: type "geometry" does not exist
```
**Solution**:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Permission Denied
```
Error: permission denied for table users
```
**Solution**: Grant proper permissions
```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_username;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_username;
```

## Testing

### Unit Tests
Create tests for repositories:
```dart
test('Create and retrieve polygon', () async {
  final repo = PolygonRepository();
  final polygon = PolygonModel(/* ... */);

  final created = await repo.createPolygon(polygon);
  expect(created.id, isNotNull);

  final retrieved = await repo.getPolygonById(created.id!);
  expect(retrieved?.type, equals(polygon.type));
});
```

### Integration Tests
Test the complete flow:
1. User signup
2. User login
3. Create polygon/point
4. Retrieve data
5. Update data
6. Delete data

## Support

For issues or questions about the migration:
1. Check PostgreSQL logs: `tail -f /var/log/postgresql/postgresql-*.log`
2. Check application logs in Flutter console
3. Verify database schema: `\d+ table_name` in psql
4. Review this guide and code comments

## Next Steps

1. Set up PostgreSQL database
2. Run schema.sql
3. Update db_config.dart with credentials
4. Test authentication (signup/login)
5. Test data submission (create polygon/point)
6. Complete remaining screen updates
7. Test offline sync
8. Migrate existing data (if applicable)
9. Deploy to production

Good luck with your migration!

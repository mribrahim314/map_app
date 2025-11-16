# Migration 002: Fix Database Constraint Issues

## Problem

The backend API was throwing the following error during user signup:

```json
{
  "success": false,
  "message": "null value in column \"id\" of relation \"users\" violates not-null constraint",
  "error": "error: null value in column \"id\" of relation \"users\" violates not-null constraint"
}
```

## Root Cause

The `users` table was defined with `id VARCHAR(255) PRIMARY KEY` without any default value or auto-generation mechanism. This was originally designed for Firebase migration where user IDs come from Firebase Auth UIDs.

However, the backend API controllers expect PostgreSQL to auto-generate the ID:

```javascript
// authController.js:33-38
const result = await query(
  `INSERT INTO users (email, password_hash, first_name, last_name, role, created_at)
   VALUES ($1, $2, $3, $4, $5, NOW())
   RETURNING id, email, first_name, last_name, role, created_at`,
  [email, hashedPassword, firstName, lastName, role]
);
```

Notice that `id` is not included in the INSERT clause, meaning the database must generate it.

## Solution

Migration 002 changes the `users.id` column from `VARCHAR(255)` to `UUID` with automatic generation using PostgreSQL's `uuid_generate_v4()` function.

### Changes Made:

1. **Users Table:**
   - Changed `id` from `VARCHAR(255)` to `UUID`
   - Added `DEFAULT uuid_generate_v4()` for auto-generation
   - Preserved existing valid UUID values during migration

2. **Foreign Key Updates:**
   - Updated `polygones.user_id` to `UUID`
   - Updated `points.user_id` to `UUID`
   - Updated `projects.created_by` to `UUID`
   - Updated `project_contributors.user_id` to `UUID`
   - Recreated all foreign key constraints

3. **Function Updates:**
   Updated all PostgreSQL functions that accept user IDs:
   - `increment_contribution_count(UUID)`
   - `add_user_to_project(INTEGER, UUID)`
   - `remove_user_from_project(INTEGER, UUID)`
   - `user_has_project_access(INTEGER, UUID)`
   - `get_polygones_in_bbox(...)` - return type updated
   - `get_points_in_bbox(...)` - return type updated

4. **View Recreations:**
   Recreated all views with correct UUID types:
   - `user_stats`
   - `adopted_polygones`
   - `adopted_points`
   - `project_stats`

## Other Tables Analysis

Reviewed all INSERT operations in the backend controllers:

### ✅ Points Table
- **Schema:** `id SERIAL PRIMARY KEY` ✓
- **Controller:** Doesn't specify `id` in INSERT ✓
- **Status:** Working correctly

### ✅ Polygons Table
- **Schema:** `id SERIAL PRIMARY KEY` ✓
- **Controller:** Doesn't specify `id` in INSERT ✓
- **Status:** Working correctly

### ✅ Projects Table
- **Schema:** `id SERIAL PRIMARY KEY` ✓
- **Controller:** Doesn't specify `id` in INSERT ✓
- **Status:** Working correctly

### ✅ Project Contributors Table
- **Schema:** Composite primary key `(project_id, user_id)` ✓
- **Controller:** Provides both values in INSERT ✓
- **Status:** Working correctly

## Migration Safety

The migration is designed to be safe and preserve existing data:

1. **Existing Records:** If there are existing users with valid UUID strings in their `id` field, those UUIDs are preserved
2. **Invalid IDs:** Any existing non-UUID IDs are replaced with newly generated UUIDs
3. **Relationships:** All foreign key relationships are maintained by mapping old IDs to new UUIDs
4. **No Data Loss:** All user data, points, polygons, and projects are preserved

## Testing

After applying this migration, test the following:

1. **User Signup:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/signup \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "password123",
       "firstName": "Test",
       "lastName": "User"
     }'
   ```

2. **User Login:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "password123"
     }'
   ```

3. **Create Point:** (with auth token)
   ```bash
   curl -X POST http://localhost:3000/api/points \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{
       "latitude": 35.8617,
       "longitude": -5.4783,
       "cropType": "Wheat"
     }'
   ```

## Rollback Considerations

If you need to rollback:

1. **Backup First:** Always backup your database before attempting rollback
2. **Manual Process:** You'll need to manually convert UUID columns back to VARCHAR
3. **Not Recommended:** Since this fixes a critical bug, rollback is not recommended

## Future Considerations

With this fix in place:

1. All new users will automatically receive a UUID
2. No need to generate IDs in the application layer
3. Consistent ID generation across all tables
4. Better compliance with PostgreSQL best practices

## Impact Summary

- **Before:** User signup would fail with constraint violation
- **After:** User signup works correctly with auto-generated UUIDs
- **Breaking Changes:** None for the API (UUIDs are returned as strings in JSON)
- **Performance:** Negligible impact; UUID generation is very fast

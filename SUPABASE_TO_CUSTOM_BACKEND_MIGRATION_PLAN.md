# Supabase to Custom Backend Migration Plan

## Executive Summary

This document outlines the complete migration strategy for transitioning the Flutter mobile application "Supervisor Work Orders" from Supabase Backend-as-a-Service (BaaS) to a custom backend solution. The app is a school supervision and maintenance management system with features including authentication, report management, photo uploads, push notifications, and real-time data synchronization.

## Current Architecture Analysis

### Technology Stack
- **Frontend**: Flutter (Dart)
- **Current Backend**: Supabase (PostgreSQL + Auth + Storage + Functions)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **State Management**: BLoC Pattern
- **HTTP Client**: Supabase Flutter SDK

### Key Features
1. **Authentication System**: User registration, login, profile management
2. **School Management**: School listings, assignments, supervisor-school relationships
3. **Report System**: Maintenance reports, damage counts, completion tracking
4. **Photo Management**: Image uploads, storage, and retrieval
5. **Push Notifications**: Real-time notifications for reports and updates
6. **Offline Support**: Local data caching and sync capabilities
7. **Achievement Tracking**: School achievement photos and submissions

### Current Database Schema

#### Core Tables
- `auth.users` - User authentication (Supabase Auth)
- `supervisors` - Supervisor profiles and details
- `schools` - School information and metadata
- `supervisor_schools` - Many-to-many relationship between supervisors and schools
- `reports` - General maintenance reports
- `maintenance_reports` - Detailed maintenance reports
- `maintenance_counts` - Maintenance counting and tracking
- `damage_counts` - Damage assessment and counting
- `school_achievements` - Achievement photo submissions
- `achievement_photos` - Individual photo records with metadata
- `damage_count_photos` - Photos for damage assessments
- `user_fcm_tokens` - FCM tokens for push notifications
- `notification_queue` - Notification queue management

## Migration Strategy Overview

### Phase 1: Backend Development (4-6 weeks)
1. **Database Migration** (1-2 weeks)
2. **API Development** (2-3 weeks)
3. **Authentication System** (1 week)
4. **File Storage Setup** (1 week)

### Phase 2: Mobile App Adaptation (2-3 weeks)
1. **Repository Layer Refactoring** (1 week)
2. **HTTP Client Implementation** (1 week)
3. **Testing and Integration** (1 week)

### Phase 3: Data Migration & Deployment (1-2 weeks)
1. **Data Export from Supabase** (3-5 days)
2. **Data Import to Custom Backend** (3-5 days)
3. **Production Deployment** (2-3 days)

## Detailed Technical Requirements

### 1. Custom Backend Technology Recommendations

#### Backend Framework Options
- **Node.js + Express** (Recommended for rapid development)
- **Python + FastAPI** (Good for data processing)
- **Java + Spring Boot** (Enterprise-grade)
- **C# + .NET Core** (Microsoft stack)

#### Database
- **PostgreSQL** (Recommended - maintains compatibility with current schema)
- **MySQL** (Alternative option)
- **MongoDB** (If document-based approach preferred)

#### File Storage
- **AWS S3** (Recommended)
- **Google Cloud Storage**
- **Azure Blob Storage**
- **MinIO** (Self-hosted option)

#### Push Notifications
- **Firebase Admin SDK** (Maintain FCM compatibility)
- **OneSignal** (Alternative)
- **Custom WebSocket implementation**

### 2. API Specifications

#### Authentication Endpoints
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/refresh
GET    /api/auth/profile
PUT    /api/auth/profile
POST   /api/auth/change-password
POST   /api/auth/reset-password
```

#### School Management Endpoints
```
GET    /api/schools
GET    /api/schools/:id
POST   /api/schools
PUT    /api/schools/:id
DELETE /api/schools/:id
GET    /api/schools/:id/supervisors
POST   /api/schools/:id/supervisors
DELETE /api/schools/:id/supervisors/:supervisorId
```

#### Report Management Endpoints
```
GET    /api/reports
GET    /api/reports/:id
POST   /api/reports
PUT    /api/reports/:id
DELETE /api/reports/:id
POST   /api/reports/:id/complete
GET    /api/reports/school/:schoolId
GET    /api/reports/supervisor/:supervisorId
```

#### Maintenance Reports Endpoints
```
GET    /api/maintenance-reports
GET    /api/maintenance-reports/:id
POST   /api/maintenance-reports
PUT    /api/maintenance-reports/:id
POST   /api/maintenance-reports/:id/complete
```

#### Damage Count Endpoints
```
GET    /api/damage-counts
GET    /api/damage-counts/:id
POST   /api/damage-counts
PUT    /api/damage-counts/:id
POST   /api/damage-counts/:id/submit
```

#### School Achievement Endpoints
```
GET    /api/school-achievements
GET    /api/school-achievements/:id
POST   /api/school-achievements
PUT    /api/school-achievements/:id
POST   /api/school-achievements/:id/submit
```

#### File Upload Endpoints
```
POST   /api/upload/photo
POST   /api/upload/multiple-photos
GET    /api/files/:fileId
DELETE /api/files/:fileId
```

#### Notification Endpoints
```
GET    /api/notifications
POST   /api/notifications/token
DELETE /api/notifications/token
POST   /api/notifications/send
```

### 3. Database Schema Migration

#### User Authentication Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    plate_numbers VARCHAR(50),
    plate_english_letters VARCHAR(10),
    plate_arabic_letters VARCHAR(10),
    iqama_id VARCHAR(50),
    work_id VARCHAR(50),
    technicians_detailed JSONB,
    email_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Schools Table
```sql
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Reports Table
```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id),
    school_name VARCHAR(255) NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES users(id),
    description TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    images JSONB DEFAULT '[]',
    completion_photos JSONB DEFAULT '[]',
    completion_note TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. Mobile App Code Changes

#### Repository Layer Refactoring

**Current Supabase Implementation:**
```dart
class AuthRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await SupabaseClientWrapper.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```

**New HTTP API Implementation:**
```dart
class AuthRepository {
  final HttpService _httpService;
  
  AuthRepository(this._httpService);
  
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _httpService.post(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data);
  }
}
```

#### HTTP Service Implementation
```dart
class HttpService {
  final Dio _dio;
  String? _accessToken;
  
  HttpService(this._dio) {
    _dio.interceptors.add(AuthInterceptor());
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic body}) {
    return _dio.post(path, data: body);
  }
  
  Future<Response> put(String path, {dynamic body}) {
    return _dio.put(path, data: body);
  }
  
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
```

#### Authentication Interceptor
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle token refresh or logout
      TokenStorage.clearTokens();
      // Navigate to login screen
    }
    handler.next(err);
  }
}
```

### 5. File Upload Implementation

#### Backend File Upload Handler (Node.js + Express)
```javascript
const multer = require('multer');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

app.post('/api/upload/photo', upload.single('photo'), async (req, res) => {
  try {
    const file = req.file;
    const fileId = uuidv4();
    const key = `uploads/${fileId}-${file.originalname}`;
    
    const uploadParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'private'
    };
    
    const result = await s3.upload(uploadParams).promise();
    
    // Save file metadata to database
    await db.query(`
      INSERT INTO file_uploads (id, original_name, file_url, file_size, mime_type, uploaded_by)
      VALUES ($1, $2, $3, $4, $5, $6)
    `, [fileId, file.originalname, result.Location, file.size, file.mimetype, req.user.id]);
    
    res.json({
      success: true,
      file_id: fileId,
      file_url: result.Location
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### Flutter File Upload Implementation
```dart
class FileUploadService {
  final HttpService _httpService;
  
  FileUploadService(this._httpService);
  
  Future<UploadResponse> uploadPhoto(File photo) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: basename(photo.path),
      ),
    });
    
    final response = await _httpService.post(
      '/api/upload/photo',
      body: formData,
    );
    
    return UploadResponse.fromJson(response.data);
  }
  
  Future<List<UploadResponse>> uploadMultiplePhotos(List<File> photos) async {
    final List<UploadResponse> results = [];
    
    for (final photo in photos) {
      final result = await uploadPhoto(photo);
      results.add(result);
    }
    
    return results;
  }
}
```

### 6. Push Notification Implementation

#### Backend Notification Service (Node.js)
```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
  })
});

class NotificationService {
  static async sendNotification(userId, title, body, data = {}) {
    try {
      // Get FCM tokens for user
      const tokens = await db.query(`
        SELECT fcm_token FROM user_fcm_tokens 
        WHERE user_id = $1 AND is_active = true
      `, [userId]);
      
      if (tokens.rows.length === 0) {
        throw new Error('No FCM tokens found for user');
      }
      
      const message = {
        notification: {
          title,
          body
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        tokens: tokens.rows.map(row => row.fcm_token)
      };
      
      const response = await admin.messaging().sendMulticast(message);
      
      // Handle failed tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens.rows[idx].fcm_token);
          }
        });
        
        // Remove invalid tokens
        await db.query(`
          UPDATE user_fcm_tokens 
          SET is_active = false 
          WHERE fcm_token = ANY($1)
        `, [failedTokens]);
      }
      
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      throw error;
    }
  }
}
```

### 7. Data Migration Strategy

#### Export Data from Supabase
```javascript
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function exportTable(tableName) {
  let allData = [];
  let from = 0;
  const batchSize = 1000;
  
  while (true) {
    const { data, error } = await supabase
      .from(tableName)
      .select('*')
      .range(from, from + batchSize - 1);
    
    if (error) throw error;
    
    if (data.length === 0) break;
    
    allData = allData.concat(data);
    from += batchSize;
    
    console.log(`Exported ${allData.length} records from ${tableName}`);
  }
  
  return allData;
}

async function exportAllData() {
  const tables = [
    'supervisors',
    'schools',
    'supervisor_schools',
    'reports',
    'maintenance_reports',
    'maintenance_counts',
    'damage_counts',
    'school_achievements',
    'achievement_photos',
    'user_fcm_tokens'
  ];
  
  const exportedData = {};
  
  for (const table of tables) {
    console.log(`Exporting ${table}...`);
    exportedData[table] = await exportTable(table);
  }
  
  // Save to file
  require('fs').writeFileSync(
    'supabase_export.json',
    JSON.stringify(exportedData, null, 2)
  );
  
  console.log('Export completed!');
}
```

#### Import Data to Custom Backend
```javascript
const fs = require('fs');
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function importData() {
  const exportedData = JSON.parse(fs.readFileSync('supabase_export.json', 'utf8'));
  
  // Import in correct order to maintain foreign key constraints
  const importOrder = [
    'supervisors',
    'schools',
    'supervisor_schools',
    'reports',
    'maintenance_reports',
    'maintenance_counts',
    'damage_counts',
    'school_achievements',
    'achievement_photos',
    'user_fcm_tokens'
  ];
  
  for (const tableName of importOrder) {
    console.log(`Importing ${tableName}...`);
    const data = exportedData[tableName];
    
    if (!data || data.length === 0) continue;
    
    // Generate INSERT query
    const columns = Object.keys(data[0]);
    const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');
    const query = `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${placeholders})`;
    
    for (const row of data) {
      const values = columns.map(col => row[col]);
      await pool.query(query, values);
    }
    
    console.log(`Imported ${data.length} records to ${tableName}`);
  }
  
  console.log('Import completed!');
}
```

### 8. Testing Strategy

#### Unit Tests
- Repository layer tests with mocked HTTP responses
- Model serialization/deserialization tests
- Business logic tests

#### Integration Tests
- API endpoint tests
- Database integration tests
- File upload/download tests
- Push notification tests

#### End-to-End Tests
- Complete user flows (login, create report, upload photos)
- Offline functionality tests
- Performance tests

### 9. Deployment Checklist

#### Pre-Migration
- [ ] Custom backend fully developed and tested
- [ ] Database schema created and validated
- [ ] File storage configured and tested
- [ ] Push notification service configured
- [ ] Data export from Supabase completed
- [ ] Mobile app updated and tested with new backend

#### Migration Day
- [ ] Deploy custom backend to production
- [ ] Import data to production database
- [ ] Update mobile app configuration
- [ ] Deploy updated mobile app
- [ ] Test all critical functionality
- [ ] Monitor for errors and performance issues

#### Post-Migration
- [ ] Verify data integrity
- [ ] Monitor application performance
- [ ] Check push notifications are working
- [ ] Validate file uploads/downloads
- [ ] User acceptance testing
- [ ] Decommission Supabase resources

### 10. Risk Mitigation

#### Data Loss Prevention
- Complete data backup before migration
- Parallel running of both systems during transition
- Rollback plan in case of critical issues

#### Performance Monitoring
- Set up application monitoring (APM)
- Database performance monitoring
- Error tracking and alerting

#### User Communication
- Notify users of planned maintenance window
- Provide support during transition period
- Document any changes in functionality

### 11. Estimated Timeline and Resources

#### Backend Development Team Requirements
- **1 Senior Backend Developer** (Full-time, 6 weeks)
- **1 DevOps Engineer** (Part-time, 2 weeks)
- **1 Database Administrator** (Part-time, 1 week)

#### Mobile Development Team Requirements
- **1 Senior Flutter Developer** (Full-time, 3 weeks)
- **1 QA Engineer** (Part-time, 2 weeks)

#### Total Estimated Timeline: 8-10 weeks
- **Weeks 1-6**: Backend development and testing
- **Weeks 4-7**: Mobile app adaptation (parallel with backend)
- **Weeks 7-8**: Integration testing and data migration
- **Weeks 9-10**: Production deployment and monitoring

### 12. Cost Considerations

#### Development Costs
- Backend development: ~240 hours
- Mobile app updates: ~120 hours
- Testing and QA: ~80 hours
- DevOps and deployment: ~40 hours

#### Infrastructure Costs
- Cloud hosting (AWS/GCP/Azure): $200-500/month
- Database hosting: $100-300/month
- File storage: $50-200/month (depending on usage)
- Monitoring and logging: $50-100/month

#### Ongoing Maintenance
- Backend maintenance: 10-20 hours/month
- Security updates and patches: 5-10 hours/month
- Performance optimization: 5-15 hours/month

## Conclusion

This migration plan provides a comprehensive roadmap for transitioning from Supabase to a custom backend solution. The phased approach minimizes risk while ensuring business continuity. The estimated timeline of 8-10 weeks allows for thorough development, testing, and deployment.

Key success factors:
1. **Thorough planning and preparation**
2. **Comprehensive testing at each phase**
3. **Proper data backup and migration procedures**
4. **Clear communication with stakeholders**
5. **Robust monitoring and rollback capabilities**

The migration will result in:
- **Greater control** over backend functionality
- **Improved performance** through optimized APIs
- **Enhanced security** with custom authentication
- **Reduced long-term costs** compared to BaaS pricing
- **Better scalability** for future requirements
# API Specifications for Custom Backend

## Overview

This document provides detailed API specifications for the custom backend that will replace Supabase functionality in the Flutter mobile application "Supervisor Work Orders".

## Base Configuration

### Base URL
```
Production: https://api.supervisor-wo.com
Staging: https://staging-api.supervisor-wo.com
Development: http://localhost:3000
```

### Authentication
All protected endpoints require Bearer token authentication:
```
Authorization: Bearer <access_token>
```

### Response Format
All API responses follow this standard format:

#### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": { ... }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Authentication Endpoints

### POST /api/auth/register
Register a new supervisor account.

**Request Body:**
```json
{
  "email": "supervisor@example.com",
  "password": "SecurePassword123!",
  "username": "john_supervisor",
  "phone": "+966501234567",
  "plate_numbers": "ABC-1234",
  "plate_english_letters": "ABC",
  "plate_arabic_letters": "أبج",
  "iqama_id": "1234567890",
  "work_id": "EMP001"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "supervisor@example.com",
      "username": "john_supervisor",
      "phone": "+966501234567",
      "email_verified": false,
      "created_at": "2024-01-15T10:30:00Z"
    },
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600
  }
}
```

### POST /api/auth/login
Authenticate supervisor and return access tokens.

**Request Body:**
```json
{
  "email": "supervisor@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "supervisor@example.com",
      "username": "john_supervisor",
      "phone": "+966501234567"
    },
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600
  }
}
```

### POST /api/auth/refresh
Refresh access token using refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600
  }
}
```

### GET /api/auth/profile
Get current user profile information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "supervisor@example.com",
    "username": "john_supervisor",
    "phone": "+966501234567",
    "plate_numbers": "ABC-1234",
    "plate_english_letters": "ABC",
    "plate_arabic_letters": "أبج",
    "iqama_id": "1234567890",
    "work_id": "EMP001",
    "technicians_detailed": [
      {
        "name": "Ahmad Technician",
        "profession": "Electrician",
        "work_id": "TECH001",
        "phone": "+966507654321"
      }
    ],
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### PUT /api/auth/profile
Update user profile information.

**Request Body:**
```json
{
  "username": "john_supervisor_updated",
  "phone": "+966501234567",
  "plate_numbers": "XYZ-5678",
  "plate_english_letters": "XYZ",
  "plate_arabic_letters": "خيز",
  "technicians_detailed": [
    {
      "name": "Ahmad Technician",
      "profession": "Electrician",
      "work_id": "TECH001",
      "phone": "+966507654321"
    }
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_supervisor_updated",
    "phone": "+966501234567",
    "updated_at": "2024-01-15T11:00:00Z"
  }
}
```

## School Management Endpoints

### GET /api/schools
Get list of schools assigned to the current supervisor.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `search` (optional): Search by school name
- `sort` (optional): Sort field (name, created_at, last_visit_date)
- `order` (optional): Sort order (asc, desc)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "schools": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Al-Noor Primary School",
        "address": "King Fahd Road, Riyadh",
        "reports_count": 15,
        "has_emergency_reports": false,
        "last_visit_date": "2024-01-10T08:00:00Z",
        "last_visit_source": "maintenance_report"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 95,
      "items_per_page": 20
    }
  }
}
```

### GET /api/schools/:id
Get detailed information about a specific school.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "name": "Al-Noor Primary School",
    "address": "King Fahd Road, Riyadh",
    "reports_count": 15,
    "has_emergency_reports": false,
    "last_visit_date": "2024-01-10T08:00:00Z",
    "last_visit_source": "maintenance_report",
    "recent_reports": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "type": "maintenance",
        "status": "completed",
        "created_at": "2024-01-10T08:00:00Z"
      }
    ],
    "maintenance_counts": 3,
    "damage_counts": 1,
    "achievements": 5
  }
}
```

## Report Management Endpoints

### GET /api/reports
Get list of reports for the current supervisor.

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page
- `status` (optional): Filter by status (pending, in_progress, completed, late, late_completed)
- `type` (optional): Filter by type (maintenance, emergency, routine)
- `priority` (optional): Filter by priority (low, medium, high, urgent)
- `school_id` (optional): Filter by school ID
- `date_from` (optional): Filter reports from date (ISO 8601)
- `date_to` (optional): Filter reports to date (ISO 8601)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "reports": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "school_name": "Al-Noor Primary School",
        "school_id": "550e8400-e29b-41d4-a716-446655440001",
        "description": "Fix broken air conditioning in classroom 101",
        "type": "maintenance",
        "priority": "high",
        "status": "pending",
        "images": [
          "https://storage.example.com/images/report-image-1.jpg"
        ],
        "completion_photos": [],
        "completion_note": null,
        "scheduled_date": "2024-01-16T09:00:00Z",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "closed_at": null
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_items": 45,
      "items_per_page": 20
    }
  }
}
```

### GET /api/reports/:id
Get detailed information about a specific report.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "school_name": "Al-Noor Primary School",
    "school_id": "550e8400-e29b-41d4-a716-446655440001",
    "supervisor_id": "550e8400-e29b-41d4-a716-446655440000",
    "supervisor_name": "john_supervisor",
    "description": "Fix broken air conditioning in classroom 101",
    "type": "maintenance",
    "priority": "high",
    "status": "pending",
    "images": [
      "https://storage.example.com/images/report-image-1.jpg",
      "https://storage.example.com/images/report-image-2.jpg"
    ],
    "completion_photos": [],
    "completion_note": null,
    "scheduled_date": "2024-01-16T09:00:00Z",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "closed_at": null
  }
}
```

### POST /api/reports
Create a new report.

**Request Body:**
```json
{
  "school_id": "550e8400-e29b-41d4-a716-446655440001",
  "description": "Fix broken air conditioning in classroom 101",
  "type": "maintenance",
  "priority": "high",
  "images": [
    "https://storage.example.com/images/report-image-1.jpg"
  ],
  "scheduled_date": "2024-01-16T09:00:00Z"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "school_name": "Al-Noor Primary School",
    "status": "pending",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### PUT /api/reports/:id
Update an existing report.

**Request Body:**
```json
{
  "description": "Fix broken air conditioning in classroom 101 - Updated description",
  "priority": "urgent",
  "status": "in_progress",
  "images": [
    "https://storage.example.com/images/report-image-1.jpg",
    "https://storage.example.com/images/report-image-2.jpg"
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "status": "in_progress",
    "updated_at": "2024-01-15T11:00:00Z"
  }
}
```

### POST /api/reports/:id/complete
Mark a report as completed with completion details.

**Request Body:**
```json
{
  "completion_note": "Air conditioning unit has been repaired and tested successfully",
  "completion_photos": [
    "https://storage.example.com/images/completion-1.jpg",
    "https://storage.example.com/images/completion-2.jpg"
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "status": "completed",
    "completion_note": "Air conditioning unit has been repaired and tested successfully",
    "completion_photos": [
      "https://storage.example.com/images/completion-1.jpg",
      "https://storage.example.com/images/completion-2.jpg"
    ],
    "closed_at": "2024-01-16T14:30:00Z",
    "updated_at": "2024-01-16T14:30:00Z"
  }
}
```

## Maintenance Reports Endpoints

### GET /api/maintenance-reports
Get list of maintenance reports.

**Query Parameters:**
- `page`, `limit`, `status`, `school_id`, `date_from`, `date_to` (same as reports)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "maintenance_reports": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440003",
        "school_id": "550e8400-e29b-41d4-a716-446655440001",
        "school_name": "Al-Noor Primary School",
        "supervisor_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "draft",
        "report_data": {
          "maintenance_items": {
            "air_conditioning": 5,
            "electrical_outlets": 12,
            "lighting": 8
          },
          "notes": "General maintenance inspection completed"
        },
        "photos": [
          "https://storage.example.com/maintenance/photo-1.jpg"
        ],
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 2,
      "total_items": 25,
      "items_per_page": 20
    }
  }
}
```

### POST /api/maintenance-reports
Create a new maintenance report.

**Request Body:**
```json
{
  "school_id": "550e8400-e29b-41d4-a716-446655440001",
  "report_data": {
    "maintenance_items": {
      "air_conditioning": 5,
      "electrical_outlets": 12,
      "lighting": 8
    },
    "notes": "General maintenance inspection completed"
  },
  "photos": [
    "https://storage.example.com/maintenance/photo-1.jpg"
  ],
  "status": "draft"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "status": "draft",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

## Damage Count Endpoints

### GET /api/damage-counts
Get list of damage count assessments.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "damage_counts": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440004",
        "school_id": "550e8400-e29b-41d4-a716-446655440001",
        "school_name": "Al-Noor Primary School",
        "supervisor_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "draft",
        "item_counts": {
          "broken_windows": 3,
          "damaged_doors": 1,
          "broken_tiles": 15
        },
        "section_photos": {
          "classroom_101": [
            "https://storage.example.com/damage/classroom-101-1.jpg"
          ]
        },
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

### POST /api/damage-counts
Create a new damage count assessment.

**Request Body:**
```json
{
  "school_id": "550e8400-e29b-41d4-a716-446655440001",
  "item_counts": {
    "broken_windows": 3,
    "damaged_doors": 1,
    "broken_tiles": 15
  },
  "section_photos": {
    "classroom_101": [
      "https://storage.example.com/damage/classroom-101-1.jpg"
    ]
  },
  "status": "draft"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440004",
    "status": "draft",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

## School Achievement Endpoints

### GET /api/school-achievements
Get list of school achievement submissions.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "achievements": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440005",
        "school_id": "550e8400-e29b-41d4-a716-446655440001",
        "school_name": "Al-Noor Primary School",
        "supervisor_id": "550e8400-e29b-41d4-a716-446655440000",
        "achievement_type": "maintenance_achievement",
        "status": "draft",
        "photos": [
          "https://storage.example.com/achievements/maintenance-1.jpg",
          "https://storage.example.com/achievements/maintenance-2.jpg"
        ],
        "notes": "Completed maintenance work on HVAC system",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "submitted_at": null
      }
    ]
  }
}
```

### POST /api/school-achievements
Create a new school achievement submission.

**Request Body:**
```json
{
  "school_id": "550e8400-e29b-41d4-a716-446655440001",
  "achievement_type": "maintenance_achievement",
  "photos": [
    "https://storage.example.com/achievements/maintenance-1.jpg",
    "https://storage.example.com/achievements/maintenance-2.jpg"
  ],
  "notes": "Completed maintenance work on HVAC system",
  "status": "draft"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440005",
    "status": "draft",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### POST /api/school-achievements/:id/submit
Submit an achievement for review.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440005",
    "status": "submitted",
    "submitted_at": "2024-01-15T11:00:00Z"
  }
}
```

## File Upload Endpoints

### POST /api/upload/photo
Upload a single photo.

**Request:**
- Content-Type: `multipart/form-data`
- Form field: `photo` (file)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "file_id": "550e8400-e29b-41d4-a716-446655440006",
    "file_url": "https://storage.example.com/uploads/photo-123.jpg",
    "original_name": "IMG_001.jpg",
    "file_size": 2048576,
    "mime_type": "image/jpeg"
  }
}
```

### POST /api/upload/multiple-photos
Upload multiple photos at once.

**Request:**
- Content-Type: `multipart/form-data`
- Form field: `photos` (multiple files)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "uploaded_files": [
      {
        "file_id": "550e8400-e29b-41d4-a716-446655440006",
        "file_url": "https://storage.example.com/uploads/photo-123.jpg",
        "original_name": "IMG_001.jpg"
      },
      {
        "file_id": "550e8400-e29b-41d4-a716-446655440007",
        "file_url": "https://storage.example.com/uploads/photo-124.jpg",
        "original_name": "IMG_002.jpg"
      }
    ],
    "total_uploaded": 2,
    "failed_uploads": []
  }
}
```

### GET /api/files/:fileId
Get file information or download file.

**Query Parameters:**
- `download` (optional): Set to `true` to download the file

**Response (200) - File Info:**
```json
{
  "success": true,
  "data": {
    "file_id": "550e8400-e29b-41d4-a716-446655440006",
    "file_url": "https://storage.example.com/uploads/photo-123.jpg",
    "original_name": "IMG_001.jpg",
    "file_size": 2048576,
    "mime_type": "image/jpeg",
    "uploaded_at": "2024-01-15T10:30:00Z",
    "uploaded_by": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

### DELETE /api/files/:fileId
Delete a file.

**Response (200):**
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

## Notification Endpoints

### POST /api/notifications/token
Register or update FCM token for push notifications.

**Request Body:**
```json
{
  "fcm_token": "dGhpcyBpcyBhIGZha2UgZmNtIHRva2Vu...",
  "device_id": "device-unique-identifier",
  "platform": "android"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "FCM token registered successfully"
}
```

### DELETE /api/notifications/token
Remove FCM token (e.g., on logout).

**Request Body:**
```json
{
  "fcm_token": "dGhpcyBpcyBhIGZha2UgZmNtIHRva2Vu..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "FCM token removed successfully"
}
```

### GET /api/notifications
Get notification history for the current user.

**Query Parameters:**
- `page`, `limit` (pagination)
- `read` (optional): Filter by read status (true/false)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440008",
        "title": "New Report Assigned",
        "body": "You have been assigned a new maintenance report at Al-Noor Primary School",
        "data": {
          "type": "new_report",
          "report_id": "550e8400-e29b-41d4-a716-446655440002",
          "school_name": "Al-Noor Primary School"
        },
        "read": false,
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 2,
      "total_items": 15,
      "items_per_page": 20
    }
  }
}
```

## Error Codes

### Authentication Errors
- `AUTH_INVALID_CREDENTIALS`: Invalid email or password
- `AUTH_TOKEN_EXPIRED`: Access token has expired
- `AUTH_TOKEN_INVALID`: Invalid or malformed token
- `AUTH_USER_NOT_FOUND`: User account not found
- `AUTH_EMAIL_ALREADY_EXISTS`: Email address already registered
- `AUTH_WEAK_PASSWORD`: Password does not meet security requirements

### Validation Errors
- `VALIDATION_REQUIRED_FIELD`: Required field is missing
- `VALIDATION_INVALID_FORMAT`: Field format is invalid
- `VALIDATION_VALUE_TOO_LONG`: Field value exceeds maximum length
- `VALIDATION_INVALID_EMAIL`: Invalid email format
- `VALIDATION_INVALID_PHONE`: Invalid phone number format

### Resource Errors
- `RESOURCE_NOT_FOUND`: Requested resource does not exist
- `RESOURCE_ACCESS_DENIED`: User does not have permission to access resource
- `RESOURCE_ALREADY_EXISTS`: Resource with same identifier already exists

### File Upload Errors
- `FILE_TOO_LARGE`: File size exceeds maximum limit
- `FILE_INVALID_TYPE`: File type not supported
- `FILE_UPLOAD_FAILED`: File upload process failed

### Server Errors
- `INTERNAL_SERVER_ERROR`: Unexpected server error
- `SERVICE_UNAVAILABLE`: Service temporarily unavailable
- `DATABASE_ERROR`: Database operation failed

## Rate Limiting

All API endpoints are subject to rate limiting:
- **Authentication endpoints**: 5 requests per minute per IP
- **File upload endpoints**: 10 requests per minute per user
- **General endpoints**: 100 requests per minute per user

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248600
```

## Pagination

All list endpoints support pagination with these parameters:
- `page`: Page number (starts from 1)
- `limit`: Items per page (default: 20, max: 100)

Pagination information is included in the response:
```json
{
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 95,
    "items_per_page": 20,
    "has_next_page": true,
    "has_prev_page": false
  }
}
```
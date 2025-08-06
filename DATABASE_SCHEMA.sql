-- ================================
-- CUSTOM BACKEND DATABASE SCHEMA
-- Migration from Supabase to Custom Backend
-- ================================
-- This schema replaces Supabase functionality for the Flutter mobile app
-- "Supervisor Work Orders" - School supervision and maintenance management system

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================
-- USER AUTHENTICATION & PROFILES
-- ================================

-- Users table (replaces Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    plate_numbers VARCHAR(50),
    plate_english_letters VARCHAR(10),
    plate_arabic_letters VARCHAR(10),
    iqama_id VARCHAR(50),
    work_id VARCHAR(50),
    technicians_detailed JSONB DEFAULT '[]',
    email_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_phone_format CHECK (phone ~* '^\+?[1-9]\d{1,14}$')
);

-- Refresh tokens for JWT authentication
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked BOOLEAN DEFAULT FALSE,
    
    -- Indexes
    INDEX idx_refresh_tokens_user_id (user_id),
    INDEX idx_refresh_tokens_expires_at (expires_at)
);

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used BOOLEAN DEFAULT FALSE,
    
    -- Indexes
    INDEX idx_password_reset_user_id (user_id),
    INDEX idx_password_reset_expires_at (expires_at)
);

-- ================================
-- SCHOOLS & ASSIGNMENTS
-- ================================

-- Schools table
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_schools_name (name)
);

-- Supervisor-School assignments (many-to-many relationship)
CREATE TABLE supervisor_schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Unique constraint to prevent duplicate assignments
    UNIQUE(supervisor_id, school_id),
    
    -- Indexes
    INDEX idx_supervisor_schools_supervisor (supervisor_id),
    INDEX idx_supervisor_schools_school (school_id)
);

-- ================================
-- REPORTS SYSTEM
-- ================================

-- Main reports table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    school_name VARCHAR(255) NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Check constraints
    CONSTRAINT chk_report_type CHECK (type IN ('maintenance', 'emergency', 'routine', 'inspection')),
    CONSTRAINT chk_report_priority CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    CONSTRAINT chk_report_status CHECK (status IN ('pending', 'in_progress', 'completed', 'late', 'late_completed', 'cancelled')),
    
    -- Indexes
    INDEX idx_reports_school_id (school_id),
    INDEX idx_reports_supervisor_id (supervisor_id),
    INDEX idx_reports_status (status),
    INDEX idx_reports_type (type),
    INDEX idx_reports_priority (priority),
    INDEX idx_reports_scheduled_date (scheduled_date),
    INDEX idx_reports_created_at (created_at)
);

-- Maintenance reports (detailed maintenance tracking)
CREATE TABLE maintenance_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    school_name VARCHAR(255) NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    report_data JSONB NOT NULL DEFAULT '{}',
    photos JSONB DEFAULT '[]',
    completion_note TEXT,
    completion_photos JSONB DEFAULT '[]',
    submitted_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Check constraints
    CONSTRAINT chk_maintenance_status CHECK (status IN ('draft', 'submitted', 'in_progress', 'completed', 'late_completed')),
    
    -- Indexes
    INDEX idx_maintenance_reports_school_id (school_id),
    INDEX idx_maintenance_reports_supervisor_id (supervisor_id),
    INDEX idx_maintenance_reports_status (status),
    INDEX idx_maintenance_reports_created_at (created_at)
);

-- ================================
-- MAINTENANCE & DAMAGE COUNTING
-- ================================

-- Maintenance counts table
CREATE TABLE maintenance_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    school_name VARCHAR(255) NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    
    -- Count data stored as JSONB for flexibility
    item_counts JSONB NOT NULL DEFAULT '{}',
    text_answers JSONB DEFAULT '{}',
    yes_no_answers JSONB DEFAULT '{}',
    yes_no_with_counts JSONB DEFAULT '{}',
    survey_answers JSONB DEFAULT '{}',
    maintenance_notes JSONB DEFAULT '{}',
    section_photos JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE,
    
    -- Check constraints
    CONSTRAINT chk_maintenance_counts_status CHECK (status IN ('draft', 'submitted')),
    
    -- Indexes
    INDEX idx_maintenance_counts_school_id (school_id),
    INDEX idx_maintenance_counts_supervisor_id (supervisor_id),
    INDEX idx_maintenance_counts_status (status),
    INDEX idx_maintenance_counts_created_at (created_at)
);

-- Damage counts table (simplified structure)
CREATE TABLE damage_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    school_name VARCHAR(255) NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    
    -- Simplified JSON fields
    item_counts JSONB NOT NULL DEFAULT '{}',
    section_photos JSONB NOT NULL DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE,
    
    -- Check constraints
    CONSTRAINT chk_damage_counts_status CHECK (status IN ('draft', 'submitted')),
    
    -- Indexes
    INDEX idx_damage_counts_school_id (school_id),
    INDEX idx_damage_counts_supervisor_id (supervisor_id),
    INDEX idx_damage_counts_status (status),
    INDEX idx_damage_counts_created_at (created_at)
);

-- Individual damage count photos table
CREATE TABLE damage_count_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    damage_count_id UUID NOT NULL REFERENCES damage_counts(id) ON DELETE CASCADE,
    section_key VARCHAR(100) NOT NULL,
    photo_url TEXT NOT NULL,
    photo_description TEXT,
    upload_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_damage_count_photos_damage_count_id (damage_count_id),
    INDEX idx_damage_count_photos_section_key (section_key)
);

-- ================================
-- SCHOOL ACHIEVEMENTS
-- ================================

-- School achievements table
CREATE TABLE school_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    school_name VARCHAR(255) NOT NULL,
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    
    -- Photo URLs array
    photos JSONB NOT NULL DEFAULT '[]',
    
    -- Optional notes/description
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE,
    
    -- Check constraints
    CONSTRAINT chk_achievement_type CHECK (achievement_type IN ('maintenance_achievement', 'ac_achievement', 'checklist')),
    CONSTRAINT chk_achievement_status CHECK (status IN ('draft', 'submitted')),
    
    -- Indexes
    INDEX idx_school_achievements_school_id (school_id),
    INDEX idx_school_achievements_supervisor_id (supervisor_id),
    INDEX idx_school_achievements_type (achievement_type),
    INDEX idx_school_achievements_status (status),
    INDEX idx_school_achievements_created_at (created_at)
);

-- Achievement photos table (individual photo records with metadata)
CREATE TABLE achievement_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    achievement_id UUID NOT NULL REFERENCES school_achievements(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_description TEXT,
    file_size BIGINT,
    mime_type VARCHAR(100),
    upload_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_achievement_photos_achievement_id (achievement_id)
);

-- ================================
-- FILE MANAGEMENT
-- ================================

-- File uploads table (track all uploaded files)
CREATE TABLE file_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_name VARCHAR(255) NOT NULL,
    stored_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    storage_provider VARCHAR(50) DEFAULT 'aws_s3',
    storage_path TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_file_uploads_uploaded_by (uploaded_by),
    INDEX idx_file_uploads_mime_type (mime_type),
    INDEX idx_file_uploads_created_at (created_at)
);

-- ================================
-- PUSH NOTIFICATIONS
-- ================================

-- FCM tokens table
CREATE TABLE user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_id VARCHAR(255),
    platform VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint for token
    UNIQUE(fcm_token),
    
    -- Check constraints
    CONSTRAINT chk_platform CHECK (platform IN ('android', 'ios')),
    
    -- Indexes
    INDEX idx_user_fcm_tokens_user_id (user_id),
    INDEX idx_user_fcm_tokens_active (is_active),
    INDEX idx_user_fcm_tokens_platform (platform)
);

-- Notification queue table
CREATE TABLE notification_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    priority VARCHAR(20) DEFAULT 'normal',
    processed BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Check constraints
    CONSTRAINT chk_notification_priority CHECK (priority IN ('low', 'normal', 'high')),
    
    -- Indexes
    INDEX idx_notification_queue_user_id (user_id),
    INDEX idx_notification_queue_processed (processed),
    INDEX idx_notification_queue_created_at (created_at),
    INDEX idx_notification_queue_priority (priority)
);

-- Notification history table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_notifications_user_id (user_id),
    INDEX idx_notifications_read (read),
    INDEX idx_notifications_created_at (created_at)
);

-- ================================
-- APP VERSION MANAGEMENT
-- ================================

-- App versions table (for update management)
CREATE TABLE app_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_name VARCHAR(20) NOT NULL,
    version_code INTEGER NOT NULL,
    platform VARCHAR(20) NOT NULL,
    minimum_supported_version INTEGER,
    force_update BOOLEAN DEFAULT FALSE,
    update_message TEXT,
    download_url TEXT,
    changelog TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Check constraints
    CONSTRAINT chk_app_platform CHECK (platform IN ('android', 'ios')),
    
    -- Unique constraint
    UNIQUE(version_code, platform),
    
    -- Indexes
    INDEX idx_app_versions_platform (platform),
    INDEX idx_app_versions_active (is_active),
    INDEX idx_app_versions_version_code (version_code)
);

-- ================================
-- AUDIT & LOGGING
-- ================================

-- Audit log table (track important actions)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_audit_logs_user_id (user_id),
    INDEX idx_audit_logs_action (action),
    INDEX idx_audit_logs_resource_type (resource_type),
    INDEX idx_audit_logs_created_at (created_at)
);

-- ================================
-- FUNCTIONS & TRIGGERS
-- ================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_reports_updated_at BEFORE UPDATE ON maintenance_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_counts_updated_at BEFORE UPDATE ON maintenance_counts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_damage_counts_updated_at BEFORE UPDATE ON damage_counts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_school_achievements_updated_at BEFORE UPDATE ON school_achievements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_fcm_tokens_updated_at BEFORE UPDATE ON user_fcm_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create audit log entries
CREATE OR REPLACE FUNCTION create_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (user_id, action, resource_type, resource_id, new_values)
        VALUES (NEW.supervisor_id, 'CREATE', TG_TABLE_NAME, NEW.id, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (user_id, action, resource_type, resource_id, old_values, new_values)
        VALUES (NEW.supervisor_id, 'UPDATE', TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (user_id, action, resource_type, resource_id, old_values)
        VALUES (OLD.supervisor_id, 'DELETE', TG_TABLE_NAME, OLD.id, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Audit triggers for important tables
CREATE TRIGGER audit_reports AFTER INSERT OR UPDATE OR DELETE ON reports FOR EACH ROW EXECUTE FUNCTION create_audit_log();
CREATE TRIGGER audit_maintenance_reports AFTER INSERT OR UPDATE OR DELETE ON maintenance_reports FOR EACH ROW EXECUTE FUNCTION create_audit_log();
CREATE TRIGGER audit_school_achievements AFTER INSERT OR UPDATE OR DELETE ON school_achievements FOR EACH ROW EXECUTE FUNCTION create_audit_log();

-- ================================
-- VIEWS FOR COMMON QUERIES
-- ================================

-- View for school statistics
CREATE VIEW school_statistics AS
SELECT 
    s.id,
    s.name,
    s.address,
    COUNT(DISTINCT r.id) as reports_count,
    COUNT(DISTINCT CASE WHEN r.priority = 'urgent' OR r.priority = 'high' THEN r.id END) as emergency_reports_count,
    MAX(CASE 
        WHEN r.status IN ('completed', 'late_completed') THEN r.closed_at
        WHEN mr.status IN ('completed', 'late_completed') THEN mr.closed_at
        ELSE NULL 
    END) as last_visit_date,
    CASE 
        WHEN MAX(r.closed_at) > MAX(mr.closed_at) OR MAX(mr.closed_at) IS NULL THEN 'report'
        WHEN MAX(mr.closed_at) > MAX(r.closed_at) OR MAX(r.closed_at) IS NULL THEN 'maintenance_report'
        ELSE NULL
    END as last_visit_source,
    s.created_at,
    s.updated_at
FROM schools s
LEFT JOIN reports r ON s.id = r.school_id
LEFT JOIN maintenance_reports mr ON s.id = mr.school_id
GROUP BY s.id, s.name, s.address, s.created_at, s.updated_at;

-- View for supervisor workload
CREATE VIEW supervisor_workload AS
SELECT 
    u.id as supervisor_id,
    u.username,
    u.email,
    COUNT(DISTINCT ss.school_id) as assigned_schools,
    COUNT(DISTINCT r.id) as total_reports,
    COUNT(DISTINCT CASE WHEN r.status IN ('pending', 'in_progress') THEN r.id END) as active_reports,
    COUNT(DISTINCT CASE WHEN r.status = 'late' THEN r.id END) as late_reports,
    COUNT(DISTINCT mr.id) as maintenance_reports,
    COUNT(DISTINCT CASE WHEN mr.status = 'draft' THEN mr.id END) as draft_maintenance_reports
FROM users u
LEFT JOIN supervisor_schools ss ON u.id = ss.supervisor_id AND ss.is_active = true
LEFT JOIN reports r ON u.id = r.supervisor_id
LEFT JOIN maintenance_reports mr ON u.id = mr.supervisor_id
WHERE u.is_active = true
GROUP BY u.id, u.username, u.email;

-- ================================
-- INITIAL DATA & CONFIGURATION
-- ================================

-- Insert initial app version
INSERT INTO app_versions (version_name, version_code, platform, minimum_supported_version, is_active)
VALUES 
    ('1.0.0', 1, 'android', 1, true),
    ('1.0.0', 1, 'ios', 1, true);

-- ================================
-- INDEXES FOR PERFORMANCE
-- ================================

-- Additional composite indexes for common queries
CREATE INDEX idx_reports_supervisor_status ON reports(supervisor_id, status);
CREATE INDEX idx_reports_school_status ON reports(school_id, status);
CREATE INDEX idx_reports_status_scheduled_date ON reports(status, scheduled_date);

CREATE INDEX idx_maintenance_reports_supervisor_status ON maintenance_reports(supervisor_id, status);
CREATE INDEX idx_maintenance_reports_school_status ON maintenance_reports(school_id, status);

CREATE INDEX idx_supervisor_schools_active ON supervisor_schools(supervisor_id, is_active);

-- Full-text search indexes
CREATE INDEX idx_schools_name_fulltext ON schools USING gin(to_tsvector('english', name));
CREATE INDEX idx_reports_description_fulltext ON reports USING gin(to_tsvector('english', description));

-- ================================
-- CLEANUP & MAINTENANCE PROCEDURES
-- ================================

-- Function to clean up old refresh tokens
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM refresh_tokens WHERE expires_at < NOW();
    DELETE FROM password_reset_tokens WHERE expires_at < NOW();
END;
$$ language 'plpgsql';

-- Function to clean up old notification queue entries
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    -- Delete processed notifications older than 30 days
    DELETE FROM notification_queue 
    WHERE processed = true AND created_at < NOW() - INTERVAL '30 days';
    
    -- Delete failed notifications older than 7 days
    DELETE FROM notification_queue 
    WHERE processed = false AND retry_count > 3 AND created_at < NOW() - INTERVAL '7 days';
END;
$$ language 'plpgsql';

-- ================================
-- COMMENTS FOR DOCUMENTATION
-- ================================

COMMENT ON TABLE users IS 'Main users table replacing Supabase auth.users';
COMMENT ON TABLE schools IS 'Schools managed by supervisors';
COMMENT ON TABLE supervisor_schools IS 'Many-to-many relationship between supervisors and schools';
COMMENT ON TABLE reports IS 'General maintenance and repair reports';
COMMENT ON TABLE maintenance_reports IS 'Detailed maintenance inspection reports';
COMMENT ON TABLE maintenance_counts IS 'Maintenance item counting and tracking';
COMMENT ON TABLE damage_counts IS 'Damage assessment and counting';
COMMENT ON TABLE school_achievements IS 'School achievement photo submissions';
COMMENT ON TABLE file_uploads IS 'Track all uploaded files and their metadata';
COMMENT ON TABLE user_fcm_tokens IS 'FCM tokens for push notifications';
COMMENT ON TABLE notification_queue IS 'Queue for processing push notifications';
COMMENT ON TABLE notifications IS 'Notification history for users';
COMMENT ON TABLE audit_logs IS 'Audit trail for important actions';

-- Grant permissions (adjust as needed for your application user)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
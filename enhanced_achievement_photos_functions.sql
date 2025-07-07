-- ================================
-- ENHANCED ACHIEVEMENT PHOTOS FUNCTIONS
-- ================================
-- SQL functions to support complex queries for school achievement photos

-- Function: Get school photo summary with counts by type
CREATE OR REPLACE FUNCTION get_school_photo_summary(supervisor_id_param UUID)
RETURNS TABLE(
    school_id UUID,
    school_name TEXT,
    achievement_type TEXT,
    photo_count BIGINT,
    latest_photo TIMESTAMPTZ,
    total_size BIGINT
) AS $$
BEGIN
    -- Check if enhanced columns exist, if not use JOIN approach
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'achievement_photos' AND column_name = 'school_id'
    ) THEN
        -- Enhanced schema version
        RETURN QUERY
        SELECT 
            ap.school_id,
            ap.school_name,
            ap.achievement_type,
            COUNT(*) as photo_count,
            MAX(ap.upload_timestamp) as latest_photo,
            COALESCE(SUM(ap.file_size), 0) as total_size
        FROM achievement_photos ap
        WHERE ap.supervisor_id = supervisor_id_param
        GROUP BY ap.school_id, ap.school_name, ap.achievement_type
        ORDER BY latest_photo DESC;
    ELSE
        -- Original schema version with JOINs
        RETURN QUERY
        SELECT 
            sa.school_id,
            sa.school_name,
            sa.achievement_type,
            COUNT(*) as photo_count,
            MAX(ap.upload_timestamp) as latest_photo,
            COALESCE(SUM(ap.file_size), 0) as total_size
        FROM achievement_photos ap
        JOIN school_achievements sa ON ap.achievement_id = sa.id
        WHERE sa.supervisor_id = supervisor_id_param
        GROUP BY sa.school_id, sa.school_name, sa.achievement_type
        ORDER BY latest_photo DESC;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get schools with their achievement photo counts
CREATE OR REPLACE FUNCTION get_schools_with_photo_counts(supervisor_id_param UUID)
RETURNS TABLE(
    school_id UUID,
    school_name TEXT,
    maintenance_photos BIGINT,
    ac_photos BIGINT,
    checklist_photos BIGINT,
    total_photos BIGINT,
    latest_upload TIMESTAMPTZ
) AS $$
BEGIN
    -- Check if enhanced columns exist, if not use JOIN approach
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'achievement_photos' AND column_name = 'school_id'
    ) THEN
        -- Enhanced schema version
        RETURN QUERY
        SELECT 
            s.id as school_id,
            s.name as school_name,
            COUNT(CASE WHEN ap.achievement_type = 'maintenance_achievement' THEN 1 END) as maintenance_photos,
            COUNT(CASE WHEN ap.achievement_type = 'ac_achievement' THEN 1 END) as ac_photos,
            COUNT(CASE WHEN ap.achievement_type = 'checklist' THEN 1 END) as checklist_photos,
            COUNT(ap.id) as total_photos,
            MAX(ap.upload_timestamp) as latest_upload
        FROM schools s
        LEFT JOIN achievement_photos ap ON s.id = ap.school_id AND ap.supervisor_id = supervisor_id_param
        WHERE s.id IN (
            SELECT ss.school_id 
            FROM supervisor_schools ss 
            WHERE ss.supervisor_id = supervisor_id_param
        )
        GROUP BY s.id, s.name
        ORDER BY latest_upload DESC NULLS LAST;
    ELSE
        -- Original schema version with JOINs
        RETURN QUERY
        SELECT 
            s.id as school_id,
            s.name as school_name,
            COUNT(CASE WHEN sa.achievement_type = 'maintenance_achievement' THEN 1 END) as maintenance_photos,
            COUNT(CASE WHEN sa.achievement_type = 'ac_achievement' THEN 1 END) as ac_photos,
            COUNT(CASE WHEN sa.achievement_type = 'checklist' THEN 1 END) as checklist_photos,
            COUNT(ap.id) as total_photos,
            MAX(ap.upload_timestamp) as latest_upload
        FROM schools s
        LEFT JOIN school_achievements sa ON s.id = sa.school_id AND sa.supervisor_id = supervisor_id_param
        LEFT JOIN achievement_photos ap ON sa.id = ap.achievement_id
        WHERE s.id IN (
            SELECT ss.school_id 
            FROM supervisor_schools ss 
            WHERE ss.supervisor_id = supervisor_id_param
        )
        GROUP BY s.id, s.name
        ORDER BY latest_upload DESC NULLS LAST;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get achievement history with photos for a school
CREATE OR REPLACE FUNCTION get_school_achievement_history_with_photos(
    school_id_param UUID, 
    supervisor_id_param UUID
)
RETURNS TABLE(
    achievement_id UUID,
    achievement_type TEXT,
    status TEXT,
    submitted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    photo_count BIGINT,
    photo_urls TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.id as achievement_id,
        sa.achievement_type,
        sa.status,
        sa.submitted_at,
        sa.created_at,
        COUNT(ap.id) as photo_count,
        ARRAY_AGG(ap.photo_url ORDER BY ap.upload_timestamp) as photo_urls
    FROM school_achievements sa
    LEFT JOIN achievement_photos ap ON sa.id = ap.achievement_id
    WHERE sa.school_id = school_id_param 
      AND sa.supervisor_id = supervisor_id_param
      AND sa.status = 'submitted'
    GROUP BY sa.id, sa.achievement_type, sa.status, sa.submitted_at, sa.created_at
    ORDER BY sa.submitted_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get daily photo upload statistics
CREATE OR REPLACE FUNCTION get_daily_photo_stats(
    supervisor_id_param UUID,
    days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
    upload_date DATE,
    maintenance_photos BIGINT,
    ac_photos BIGINT,
    checklist_photos BIGINT,
    total_photos BIGINT,
    schools_count BIGINT
) AS $$
BEGIN
    -- Check if enhanced columns exist, if not use JOIN approach
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'achievement_photos' AND column_name = 'school_id'
    ) THEN
        -- Enhanced schema version
        RETURN QUERY
        SELECT 
            ap.upload_timestamp::DATE as upload_date,
            COUNT(CASE WHEN ap.achievement_type = 'maintenance_achievement' THEN 1 END) as maintenance_photos,
            COUNT(CASE WHEN ap.achievement_type = 'ac_achievement' THEN 1 END) as ac_photos,
            COUNT(CASE WHEN ap.achievement_type = 'checklist' THEN 1 END) as checklist_photos,
            COUNT(ap.id) as total_photos,
            COUNT(DISTINCT ap.school_id) as schools_count
        FROM achievement_photos ap
        WHERE ap.supervisor_id = supervisor_id_param
          AND ap.upload_timestamp >= CURRENT_DATE - INTERVAL '%s days' % days_back
        GROUP BY ap.upload_timestamp::DATE
        ORDER BY upload_date DESC;
    ELSE
        -- Original schema version with JOINs
        RETURN QUERY
        SELECT 
            ap.upload_timestamp::DATE as upload_date,
            COUNT(CASE WHEN sa.achievement_type = 'maintenance_achievement' THEN 1 END) as maintenance_photos,
            COUNT(CASE WHEN sa.achievement_type = 'ac_achievement' THEN 1 END) as ac_photos,
            COUNT(CASE WHEN sa.achievement_type = 'checklist' THEN 1 END) as checklist_photos,
            COUNT(ap.id) as total_photos,
            COUNT(DISTINCT sa.school_id) as schools_count
        FROM achievement_photos ap
        JOIN school_achievements sa ON ap.achievement_id = sa.id
        WHERE sa.supervisor_id = supervisor_id_param
          AND ap.upload_timestamp >= CURRENT_DATE - INTERVAL '%s days' % days_back
        GROUP BY ap.upload_timestamp::DATE
        ORDER BY upload_date DESC;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get photo upload progress for schools
CREATE OR REPLACE FUNCTION get_school_photo_progress(supervisor_id_param UUID)
RETURNS TABLE(
    school_id UUID,
    school_name TEXT,
    has_maintenance_photos BOOLEAN,
    has_ac_photos BOOLEAN,
    has_checklist_photos BOOLEAN,
    completion_percentage NUMERIC,
    latest_activity TIMESTAMPTZ
) AS $$
BEGIN
    -- Check if enhanced columns exist, if not use JOIN approach
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'achievement_photos' AND column_name = 'school_id'
    ) THEN
        -- Enhanced schema version
        RETURN QUERY
        SELECT 
            s.id as school_id,
            s.name as school_name,
            (COUNT(CASE WHEN ap.achievement_type = 'maintenance_achievement' THEN 1 END) > 0) as has_maintenance_photos,
            (COUNT(CASE WHEN ap.achievement_type = 'ac_achievement' THEN 1 END) > 0) as has_ac_photos,
            (COUNT(CASE WHEN ap.achievement_type = 'checklist' THEN 1 END) > 0) as has_checklist_photos,
            ROUND(
                (COUNT(DISTINCT ap.achievement_type) * 100.0 / 3.0), 2
            ) as completion_percentage,
            MAX(ap.upload_timestamp) as latest_activity
        FROM schools s
        LEFT JOIN achievement_photos ap ON s.id = ap.school_id AND ap.supervisor_id = supervisor_id_param
        WHERE s.id IN (
            SELECT ss.school_id 
            FROM supervisor_schools ss 
            WHERE ss.supervisor_id = supervisor_id_param
        )
        GROUP BY s.id, s.name
        ORDER BY completion_percentage DESC, latest_activity DESC NULLS LAST;
    ELSE
        -- Original schema version with JOINs
        RETURN QUERY
        SELECT 
            s.id as school_id,
            s.name as school_name,
            (COUNT(CASE WHEN sa.achievement_type = 'maintenance_achievement' THEN 1 END) > 0) as has_maintenance_photos,
            (COUNT(CASE WHEN sa.achievement_type = 'ac_achievement' THEN 1 END) > 0) as has_ac_photos,
            (COUNT(CASE WHEN sa.achievement_type = 'checklist' THEN 1 END) > 0) as has_checklist_photos,
            ROUND(
                (COUNT(DISTINCT sa.achievement_type) * 100.0 / 3.0), 2
            ) as completion_percentage,
            MAX(ap.upload_timestamp) as latest_activity
        FROM schools s
        LEFT JOIN school_achievements sa ON s.id = sa.school_id AND sa.supervisor_id = supervisor_id_param
        LEFT JOIN achievement_photos ap ON sa.id = ap.achievement_id
        WHERE s.id IN (
            SELECT ss.school_id 
            FROM supervisor_schools ss 
            WHERE ss.supervisor_id = supervisor_id_param
        )
        GROUP BY s.id, s.name
        ORDER BY completion_percentage DESC, latest_activity DESC NULLS LAST;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get recent photo uploads across all schools
CREATE OR REPLACE FUNCTION get_recent_photo_uploads(
    supervisor_id_param UUID,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE(
    photo_id UUID,
    school_id UUID,
    school_name TEXT,
    achievement_type TEXT,
    photo_url TEXT,
    photo_description TEXT,
    upload_timestamp TIMESTAMPTZ,
    file_size BIGINT
) AS $$
BEGIN
    -- Check if enhanced columns exist, if not use JOIN approach
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'achievement_photos' AND column_name = 'school_id'
    ) THEN
        -- Enhanced schema version
        RETURN QUERY
        SELECT 
            ap.id as photo_id,
            ap.school_id,
            ap.school_name,
            ap.achievement_type,
            ap.photo_url,
            ap.photo_description,
            ap.upload_timestamp,
            ap.file_size
        FROM achievement_photos ap
        WHERE ap.supervisor_id = supervisor_id_param
        ORDER BY ap.upload_timestamp DESC
        LIMIT limit_count;
    ELSE
        -- Original schema version with JOINs
        RETURN QUERY
        SELECT 
            ap.id as photo_id,
            sa.school_id,
            sa.school_name,
            sa.achievement_type,
            ap.photo_url,
            ap.photo_description,
            ap.upload_timestamp,
            ap.file_size
        FROM achievement_photos ap
        JOIN school_achievements sa ON ap.achievement_id = sa.id
        WHERE sa.supervisor_id = supervisor_id_param
        ORDER BY ap.upload_timestamp DESC
        LIMIT limit_count;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_school_photo_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_schools_with_photo_counts(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_school_achievement_history_with_photos(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_photo_stats(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_school_photo_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_photo_uploads(UUID, INTEGER) TO authenticated;

-- ================================
-- USEFUL VIEWS FOR EASIER QUERIES
-- ================================

-- View: School achievement photos with full context
-- This view works with the current schema using JOINs
CREATE OR REPLACE VIEW v_school_achievement_photos AS
SELECT 
    ap.id as photo_id,
    ap.photo_url,
    ap.photo_description,
    ap.file_size,
    ap.mime_type,
    ap.upload_timestamp,
    sa.school_id,
    sa.school_name,
    sa.achievement_type,
    sa.supervisor_id,
    sa.id as achievement_id,
    sa.status as achievement_status,
    sa.submitted_at,
    sa.created_at as achievement_created_at,
    CASE sa.achievement_type
        WHEN 'maintenance_achievement' THEN 'مشهد صيانة'
        WHEN 'ac_achievement' THEN 'مشهد تكييف'
        WHEN 'checklist' THEN 'تشيك ليست'
        ELSE sa.achievement_type
    END as achievement_type_arabic
FROM achievement_photos ap
JOIN school_achievements sa ON ap.achievement_id = sa.id;

-- Grant select permission on the view
GRANT SELECT ON v_school_achievement_photos TO authenticated;

-- View: School photo summary
-- This view works with the current schema using JOINs
CREATE OR REPLACE VIEW v_school_photo_summary AS
SELECT 
    s.id as school_id,
    s.name as school_name,
    s.address as school_address,
    COUNT(CASE WHEN sa.achievement_type = 'maintenance_achievement' THEN 1 END) as maintenance_photos,
    COUNT(CASE WHEN sa.achievement_type = 'ac_achievement' THEN 1 END) as ac_photos,
    COUNT(CASE WHEN sa.achievement_type = 'checklist' THEN 1 END) as checklist_photos,
    COUNT(ap.id) as total_photos,
    MAX(ap.upload_timestamp) as latest_upload,
    COUNT(DISTINCT sa.achievement_type) as completed_types,
    ROUND((COUNT(DISTINCT sa.achievement_type) * 100.0 / 3.0), 2) as completion_percentage
FROM schools s
LEFT JOIN school_achievements sa ON s.id = sa.school_id
LEFT JOIN achievement_photos ap ON sa.id = ap.achievement_id
GROUP BY s.id, s.name, s.address;

-- Grant select permission on the view
GRANT SELECT ON v_school_photo_summary TO authenticated; 
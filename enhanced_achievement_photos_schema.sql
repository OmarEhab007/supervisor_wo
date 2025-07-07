-- ================================
-- ENHANCED ACHIEVEMENT PHOTOS SCHEMA
-- ================================
-- This enhancement adds direct school and achievement type links
-- to the photos table for easier querying by school

-- Enhanced Achievement photos table with direct school links
ALTER TABLE achievement_photos 
ADD COLUMN IF NOT EXISTS school_id UUID,
ADD COLUMN IF NOT EXISTS school_name TEXT,
ADD COLUMN IF NOT EXISTS achievement_type TEXT,
ADD COLUMN IF NOT EXISTS supervisor_id UUID;

-- Add foreign key constraints for the new columns (with proper error handling)
DO $$
BEGIN
    -- Add foreign key constraint for school_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_achievement_photos_school'
        AND table_name = 'achievement_photos'
    ) THEN
        ALTER TABLE achievement_photos 
        ADD CONSTRAINT fk_achievement_photos_school 
        FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;
    END IF;

    -- Add foreign key constraint for supervisor_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_achievement_photos_supervisor'
        AND table_name = 'achievement_photos'
    ) THEN
        ALTER TABLE achievement_photos 
        ADD CONSTRAINT fk_achievement_photos_supervisor 
        FOREIGN KEY (supervisor_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    -- Add check constraint for achievement_type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'chk_achievement_photos_type'
        AND table_name = 'achievement_photos'
    ) THEN
        ALTER TABLE achievement_photos 
        ADD CONSTRAINT chk_achievement_photos_type 
        CHECK (achievement_type IN ('maintenance_achievement', 'ac_achievement', 'checklist'));
    END IF;
END $$;

-- ================================
-- ENHANCED INDEXES FOR PERFORMANCE
-- ================================

-- Direct school lookup indexes
CREATE INDEX IF NOT EXISTS idx_achievement_photos_school_id ON achievement_photos(school_id);
CREATE INDEX IF NOT EXISTS idx_achievement_photos_supervisor_id ON achievement_photos(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_achievement_photos_achievement_type ON achievement_photos(achievement_type);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_achievement_photos_school_type ON achievement_photos(school_id, achievement_type);
CREATE INDEX IF NOT EXISTS idx_achievement_photos_school_supervisor ON achievement_photos(school_id, supervisor_id);
CREATE INDEX IF NOT EXISTS idx_achievement_photos_type_supervisor ON achievement_photos(achievement_type, supervisor_id);

-- Triple composite for the most common query pattern
CREATE INDEX IF NOT EXISTS idx_achievement_photos_school_type_supervisor ON achievement_photos(school_id, achievement_type, supervisor_id);

-- ================================
-- ENHANCED ROW LEVEL SECURITY
-- ================================

-- Drop existing policies to recreate with enhanced logic
DROP POLICY IF EXISTS "Users can view own achievement photos" ON achievement_photos;
DROP POLICY IF EXISTS "Users can create own achievement photos" ON achievement_photos;
DROP POLICY IF EXISTS "Users can update own achievement photos" ON achievement_photos;
DROP POLICY IF EXISTS "Users can delete own achievement photos" ON achievement_photos;

-- Enhanced policies using direct supervisor_id
CREATE POLICY "Users can view own achievement photos enhanced" ON achievement_photos
    FOR SELECT USING (auth.uid() = supervisor_id);

CREATE POLICY "Users can create own achievement photos enhanced" ON achievement_photos
    FOR INSERT WITH CHECK (auth.uid() = supervisor_id);

CREATE POLICY "Users can update own achievement photos enhanced" ON achievement_photos
    FOR UPDATE USING (auth.uid() = supervisor_id);

CREATE POLICY "Users can delete own achievement photos enhanced" ON achievement_photos
    FOR DELETE USING (auth.uid() = supervisor_id);

-- ================================
-- DATA MIGRATION FUNCTION
-- ================================

-- Function to populate the new columns from existing data
CREATE OR REPLACE FUNCTION migrate_achievement_photos_data()
RETURNS void AS $$
BEGIN
    -- Update achievement_photos with data from school_achievements
    UPDATE achievement_photos ap
    SET 
        school_id = sa.school_id,
        school_name = sa.school_name,
        achievement_type = sa.achievement_type,
        supervisor_id = sa.supervisor_id
    FROM school_achievements sa
    WHERE ap.achievement_id = sa.id
    AND (ap.school_id IS NULL OR ap.achievement_type IS NULL OR ap.supervisor_id IS NULL);
    
    RAISE NOTICE 'Achievement photos data migration completed';
END;
$$ LANGUAGE plpgsql;

-- Run the migration
SELECT migrate_achievement_photos_data();

-- ================================
-- TRIGGER FOR AUTO-POPULATION
-- ================================

-- Function to automatically populate new photo records
CREATE OR REPLACE FUNCTION auto_populate_achievement_photo_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Get school and achievement data when inserting new photo
    IF NEW.school_id IS NULL OR NEW.achievement_type IS NULL OR NEW.supervisor_id IS NULL THEN
        SELECT 
            sa.school_id,
            sa.school_name,
            sa.achievement_type,
            sa.supervisor_id
        INTO 
            NEW.school_id,
            NEW.school_name,
            NEW.achievement_type,
            NEW.supervisor_id
        FROM school_achievements sa
        WHERE sa.id = NEW.achievement_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-populate data on insert
CREATE TRIGGER auto_populate_achievement_photo_data_trigger
    BEFORE INSERT ON achievement_photos
    FOR EACH ROW
    EXECUTE FUNCTION auto_populate_achievement_photo_data();

-- ================================
-- ENHANCED USEFUL QUERIES
-- ================================

-- Query: Get all photos for a specific school
/*
SELECT * FROM achievement_photos 
WHERE school_id = $1 
  AND supervisor_id = auth.uid()
ORDER BY upload_timestamp DESC;
*/

-- Query: Get photos by school and achievement type
/*
SELECT * FROM achievement_photos 
WHERE school_id = $1 
  AND achievement_type = $2
  AND supervisor_id = auth.uid()
ORDER BY upload_timestamp DESC;
*/

-- Query: Get photo summary by school
/*
SELECT 
    school_id,
    school_name,
    achievement_type,
    COUNT(*) as photo_count,
    MAX(upload_timestamp) as latest_photo,
    COALESCE(SUM(file_size), 0) as total_size
FROM achievement_photos 
WHERE supervisor_id = auth.uid()
GROUP BY school_id, school_name, achievement_type
ORDER BY latest_photo DESC;
*/

-- Query: Get schools with their achievement photo counts
/*
SELECT 
    s.id as school_id,
    s.name as school_name,
    COUNT(CASE WHEN ap.achievement_type = 'maintenance_achievement' THEN 1 END) as maintenance_photos,
    COUNT(CASE WHEN ap.achievement_type = 'ac_achievement' THEN 1 END) as ac_photos,
    COUNT(CASE WHEN ap.achievement_type = 'checklist' THEN 1 END) as checklist_photos,
    COUNT(ap.id) as total_photos,
    MAX(ap.upload_timestamp) as latest_upload
FROM schools s
LEFT JOIN achievement_photos ap ON s.id = ap.school_id AND ap.supervisor_id = auth.uid()
GROUP BY s.id, s.name
ORDER BY latest_upload DESC NULLS LAST;
*/

-- Query: Get achievement history with photos for a school
/*
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
WHERE sa.school_id = $1 
  AND sa.supervisor_id = auth.uid()
  AND sa.status = 'submitted'
GROUP BY sa.id, sa.achievement_type, sa.status, sa.submitted_at, sa.created_at
ORDER BY sa.submitted_at DESC;
*/ 
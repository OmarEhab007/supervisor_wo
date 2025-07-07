-- ================================
-- SCHOOL ACHIEVEMENTS DATABASE SCHEMA
-- ================================
-- This schema handles photo submissions for:
-- 1. مشهد صيانة (Maintenance Achievement)
-- 2. مشهد تكييف (AC Achievement) 
-- 3. تشيك ليست (Checklist)

-- Main achievements table
CREATE TABLE IF NOT EXISTS school_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL,
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL,
    achievement_type TEXT NOT NULL, -- 'maintenance_achievement', 'ac_achievement', 'checklist'
    status TEXT NOT NULL DEFAULT 'draft',
    
    -- Photo URLs array
    photos JSONB NOT NULL DEFAULT '[]',
    
    -- Optional notes/description
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    
    -- Foreign key constraints
    CONSTRAINT fk_school_achievements_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    CONSTRAINT fk_school_achievements_supervisor FOREIGN KEY (supervisor_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_achievement_type CHECK (achievement_type IN ('maintenance_achievement', 'ac_achievement', 'checklist')),
    CONSTRAINT chk_achievement_status CHECK (status IN ('draft', 'submitted'))
);

-- Achievement photos table (for individual photo records with metadata)
CREATE TABLE IF NOT EXISTS achievement_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    achievement_id UUID NOT NULL,
    photo_url TEXT NOT NULL,
    photo_description TEXT,
    file_size BIGINT, -- in bytes
    mime_type TEXT,
    upload_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Foreign key constraint
    CONSTRAINT fk_achievement_photos_achievement FOREIGN KEY (achievement_id) REFERENCES school_achievements(id) ON DELETE CASCADE
);

-- ================================
-- INDEXES FOR PERFORMANCE
-- ================================

-- Main lookup indexes
CREATE INDEX IF NOT EXISTS idx_school_achievements_school_id ON school_achievements(school_id);
CREATE INDEX IF NOT EXISTS idx_school_achievements_supervisor_id ON school_achievements(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_school_achievements_type ON school_achievements(achievement_type);
CREATE INDEX IF NOT EXISTS idx_school_achievements_status ON school_achievements(status);
CREATE INDEX IF NOT EXISTS idx_school_achievements_created_at ON school_achievements(created_at);
CREATE INDEX IF NOT EXISTS idx_school_achievements_submitted_at ON school_achievements(submitted_at);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_school_achievements_school_supervisor ON school_achievements(school_id, supervisor_id);
CREATE INDEX IF NOT EXISTS idx_school_achievements_type_status ON school_achievements(achievement_type, status);
CREATE INDEX IF NOT EXISTS idx_school_achievements_school_type ON school_achievements(school_id, achievement_type);

-- Photo table indexes
CREATE INDEX IF NOT EXISTS idx_achievement_photos_achievement_id ON achievement_photos(achievement_id);
CREATE INDEX IF NOT EXISTS idx_achievement_photos_upload_timestamp ON achievement_photos(upload_timestamp);

-- ================================
-- ROW LEVEL SECURITY (RLS)
-- ================================

-- Enable RLS on school_achievements table
ALTER TABLE school_achievements ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own achievements
CREATE POLICY "Users can view own achievements" ON school_achievements
    FOR SELECT USING (auth.uid() = supervisor_id);

-- Policy: Users can create their own achievements
CREATE POLICY "Users can create own achievements" ON school_achievements
    FOR INSERT WITH CHECK (auth.uid() = supervisor_id);

-- Policy: Users can update their own achievements
CREATE POLICY "Users can update own achievements" ON school_achievements
    FOR UPDATE USING (auth.uid() = supervisor_id);

-- Policy: Users can delete their own achievements
CREATE POLICY "Users can delete own achievements" ON school_achievements
    FOR DELETE USING (auth.uid() = supervisor_id);

-- Enable RLS on achievement_photos table
ALTER TABLE achievement_photos ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see photos of their own achievements
CREATE POLICY "Users can view own achievement photos" ON achievement_photos
    FOR SELECT USING (
        achievement_id IN (
            SELECT id FROM school_achievements WHERE supervisor_id = auth.uid()
        )
    );

-- Policy: Users can create photos for their own achievements
CREATE POLICY "Users can create own achievement photos" ON achievement_photos
    FOR INSERT WITH CHECK (
        achievement_id IN (
            SELECT id FROM school_achievements WHERE supervisor_id = auth.uid()
        )
    );

-- Policy: Users can update photos of their own achievements
CREATE POLICY "Users can update own achievement photos" ON achievement_photos
    FOR UPDATE USING (
        achievement_id IN (
            SELECT id FROM school_achievements WHERE supervisor_id = auth.uid()
        )
    );

-- Policy: Users can delete photos of their own achievements
CREATE POLICY "Users can delete own achievement photos" ON achievement_photos
    FOR DELETE USING (
        achievement_id IN (
            SELECT id FROM school_achievements WHERE supervisor_id = auth.uid()
        )
    );

-- ================================
-- FUNCTIONS AND TRIGGERS
-- ================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_school_achievements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    -- Set submitted_at when status changes to submitted
    IF NEW.status = 'submitted' AND OLD.status != 'submitted' THEN
        NEW.submitted_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update timestamps on school_achievements table
CREATE TRIGGER update_school_achievements_updated_at
    BEFORE UPDATE ON school_achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_school_achievements_updated_at();

-- ================================
-- USEFUL QUERIES FOR THE APP
-- ================================

-- Query: Get all achievements for a supervisor
/*
SELECT * FROM school_achievements 
WHERE supervisor_id = auth.uid() 
ORDER BY created_at DESC;
*/

-- Query: Get achievements for a specific school and type
/*
SELECT * FROM school_achievements 
WHERE school_id = $1 
  AND supervisor_id = auth.uid() 
  AND achievement_type = $2
ORDER BY created_at DESC;
*/

-- Query: Get latest achievement submission date for each type per school
/*
SELECT 
    school_id,
    achievement_type,
    MAX(submitted_at) as last_submission,
    COUNT(*) as total_submissions
FROM school_achievements 
WHERE supervisor_id = auth.uid() 
  AND status = 'submitted'
GROUP BY school_id, achievement_type
ORDER BY last_submission DESC;
*/

-- Query: Get achievement with photo count
/*
SELECT 
    sa.*,
    COUNT(ap.id) as photo_count,
    COALESCE(SUM(ap.file_size), 0) as total_file_size
FROM school_achievements sa
LEFT JOIN achievement_photos ap ON sa.id = ap.achievement_id
WHERE sa.supervisor_id = auth.uid()
GROUP BY sa.id
ORDER BY sa.created_at DESC;
*/

-- Query: Get achievements history for a school
/*
SELECT 
    sa.*,
    COUNT(ap.id) as photo_count
FROM school_achievements sa
LEFT JOIN achievement_photos ap ON sa.id = ap.achievement_id
WHERE sa.school_id = $1 
  AND sa.supervisor_id = auth.uid()
  AND sa.status = 'submitted'
GROUP BY sa.id
ORDER BY sa.submitted_at DESC;
*/

-- ================================
-- SAMPLE DATA STRUCTURE
-- ================================

/*
Expected data structure:

1. school_achievements table:
   - id: UUID
   - school_id: UUID (foreign key to schools)
   - school_name: TEXT (denormalized for easier queries)
   - supervisor_id: UUID (foreign key to auth.users)
   - achievement_type: 'maintenance_achievement' | 'ac_achievement' | 'checklist'
   - status: 'draft' | 'submitted'
   - photos: JSONB array of photo URLs
   - notes: TEXT (optional description)
   - created_at, updated_at, submitted_at: timestamps

2. achievement_photos table:
   - id: UUID
   - achievement_id: UUID (foreign key to school_achievements)
   - photo_url: TEXT (Cloudinary URL)
   - photo_description: TEXT (optional)
   - file_size: BIGINT (bytes)
   - mime_type: TEXT (image/jpeg, image/png, etc.)
   - upload_timestamp: TIMESTAMPTZ

3. Achievement Types:
   - maintenance_achievement: مشهد صيانة
   - ac_achievement: مشهد تكييف
   - checklist: تشيك ليست
*/

-- ================================
-- SAMPLE DATA INSERTION
-- ================================

-- Example: Insert an achievement record
/*
INSERT INTO school_achievements (
    school_id, 
    school_name, 
    supervisor_id, 
    achievement_type,
    status,
    photos,
    notes
) VALUES (
    '12345678-1234-1234-1234-123456789012'::uuid,
    'مدرسة الملك عبدالعزيز الابتدائية',
    '87654321-4321-4321-4321-210987654321'::uuid,
    'maintenance_achievement',
    'submitted',
    '["https://res.cloudinary.com/example/image/upload/v1234567890/photo1.jpg", "https://res.cloudinary.com/example/image/upload/v1234567890/photo2.jpg"]'::jsonb,
    'تم إنجاز أعمال الصيانة بنجاح'
);
*/ 
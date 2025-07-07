-- ================================
-- DAMAGE COUNT SYSTEM DATABASE SCHEMA (SIMPLIFIED)
-- ================================
-- This schema is designed for Supabase (PostgreSQL)
-- Based on simplified DamageCountModel structure

-- Note: Schools table already exists with supervisor assignments
-- The system uses existing 'schools' and 'supervisor_schools' tables

-- Create damage_counts table (main table) - SIMPLIFIED
CREATE TABLE IF NOT EXISTS damage_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL,
    school_name TEXT NOT NULL,
    supervisor_id UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    
    -- Simplified JSON fields - only what's needed
    item_counts JSONB NOT NULL DEFAULT '{}',      -- Only numeric counts
    section_photos JSONB NOT NULL DEFAULT '{}',  -- Photos by section
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    -- Foreign key constraints (assuming schools and users tables exist)
    CONSTRAINT fk_damage_counts_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    CONSTRAINT fk_damage_counts_supervisor FOREIGN KEY (supervisor_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_damage_counts_status CHECK (status IN ('draft', 'submitted'))
);

-- Create damage_count_photos table (for individual photo records)
CREATE TABLE IF NOT EXISTS damage_count_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    damage_count_id UUID NOT NULL,
    section_key TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    photo_description TEXT,
    upload_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Foreign key constraint
    CONSTRAINT fk_damage_count_photos_damage_count FOREIGN KEY (damage_count_id) REFERENCES damage_counts(id) ON DELETE CASCADE
);

-- ================================
-- INDEXES FOR PERFORMANCE
-- ================================

-- Main lookup indexes
CREATE INDEX IF NOT EXISTS idx_damage_counts_school_id ON damage_counts(school_id);
CREATE INDEX IF NOT EXISTS idx_damage_counts_supervisor_id ON damage_counts(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_damage_counts_status ON damage_counts(status);
CREATE INDEX IF NOT EXISTS idx_damage_counts_created_at ON damage_counts(created_at);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_damage_counts_school_supervisor ON damage_counts(school_id, supervisor_id);
CREATE INDEX IF NOT EXISTS idx_damage_counts_status_created ON damage_counts(status, created_at);

-- Photo table indexes
CREATE INDEX IF NOT EXISTS idx_damage_count_photos_damage_count_id ON damage_count_photos(damage_count_id);
CREATE INDEX IF NOT EXISTS idx_damage_count_photos_section_key ON damage_count_photos(section_key);

-- ================================
-- ROW LEVEL SECURITY (RLS)
-- ================================

-- Enable RLS on damage_counts table
ALTER TABLE damage_counts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own damage counts
CREATE POLICY "Users can view own damage counts" ON damage_counts
    FOR SELECT USING (auth.uid() = supervisor_id);

-- Policy: Users can create their own damage counts
CREATE POLICY "Users can create own damage counts" ON damage_counts
    FOR INSERT WITH CHECK (auth.uid() = supervisor_id);

-- Policy: Users can update their own damage counts
CREATE POLICY "Users can update own damage counts" ON damage_counts
    FOR UPDATE USING (auth.uid() = supervisor_id);

-- Policy: Users can delete their own damage counts
CREATE POLICY "Users can delete own damage counts" ON damage_counts
    FOR DELETE USING (auth.uid() = supervisor_id);

-- Enable RLS on damage_count_photos table
ALTER TABLE damage_count_photos ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see photos of their own damage counts
CREATE POLICY "Users can view own damage count photos" ON damage_count_photos
    FOR SELECT USING (
        damage_count_id IN (
            SELECT id FROM damage_counts WHERE supervisor_id = auth.uid()
        )
    );

-- Policy: Users can create photos for their own damage counts
CREATE POLICY "Users can create own damage count photos" ON damage_count_photos
    FOR INSERT WITH CHECK (
        damage_count_id IN (
            SELECT id FROM damage_counts WHERE supervisor_id = auth.uid()
        )
    );

-- Policy: Users can update photos of their own damage counts
CREATE POLICY "Users can update own damage count photos" ON damage_count_photos
    FOR UPDATE USING (
        damage_count_id IN (
            SELECT id FROM damage_counts WHERE supervisor_id = auth.uid()
        )
    );

-- Policy: Users can delete photos of their own damage counts
CREATE POLICY "Users can delete own damage count photos" ON damage_count_photos
    FOR DELETE USING (
        damage_count_id IN (
            SELECT id FROM damage_counts WHERE supervisor_id = auth.uid()
        )
    );

-- ================================
-- FUNCTIONS AND TRIGGERS
-- ================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update updated_at on damage_counts table
CREATE TRIGGER update_damage_counts_updated_at
    BEFORE UPDATE ON damage_counts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================================
-- SAMPLE DATA STRUCTURE
-- ================================

/*
Expected data structure in JSON fields:

1. item_counts (JSONB):
   - Contains counts for all damaged items across categories
   - Categories: mechanical_plumbing, electrical, civil, safety_security, air_conditioning
   - Example: {"plastic_chair": 5, "water_sink": 2, "split_ac": 3}

2. section_photos (JSONB):
   - Contains photo URLs organized by category
   - Example: {"mechanical_plumbing": ["url1.jpg"], "electrical": ["url2.jpg"]}

3. Categories breakdown:
   - mechanical_plumbing: 11 items (chairs, sinks, pipes, tanks, pumps, etc.)
   - electrical: 9 items (circuit breakers, panels, cables, heaters)
   - civil: 1 item (UPVC fabric)
   - safety_security: 7 items (fire equipment, alarms, etc.)
   - air_conditioning: 4 items (cabinet, split, window, package units)

4. Foreign Key Dependencies:
   - school_id must exist in schools table
   - supervisor_id must exist in auth.users table
*/

-- ================================
-- SAMPLE DATA INSERTION
-- ================================

-- Example: Insert a damage count record
/*
INSERT INTO damage_counts (
    school_id, 
    school_name, 
    supervisor_id, 
    status,
    item_counts,
    section_photos
) VALUES (
    '12345678-1234-1234-1234-123456789012'::uuid,
    'مدرسة الملك عبدالعزيز الابتدائية',
    '87654321-4321-4321-4321-210987654321'::uuid,
    'submitted',
    '{"plastic_chair": 5, "water_sink": 2, "circuit_breaker_250": 1, "split_ac": 3, "cabinet_ac": 1}'::jsonb,
    '{"mechanical_plumbing": ["https://example.com/photo1.jpg"], "electrical": ["https://example.com/photo2.jpg"], "air_conditioning": ["https://example.com/photo3.jpg"]}'::jsonb
);
*/

-- ================================
-- USEFUL QUERIES FOR THE APP
-- ================================

-- Query: Get all damage counts for a supervisor
/*
SELECT * FROM damage_counts 
WHERE supervisor_id = auth.uid() 
ORDER BY created_at DESC;
*/

-- Query: Get damage counts for a specific school
/*
SELECT * FROM damage_counts 
WHERE school_id = $1 AND supervisor_id = auth.uid()
ORDER BY created_at DESC;
*/

-- Query: Get total damaged items count for a damage count record
/*
SELECT 
    id,
    school_name,
    (SELECT SUM(value::int) 
     FROM jsonb_each_text(item_counts) 
     WHERE value ~ '^[0-9]+$'
    ) as total_damaged_items
FROM damage_counts 
WHERE id = $1;
*/

-- Query: Get damage count with photo count
/*
SELECT 
    dc.*,
    COUNT(dcp.id) as photo_count
FROM damage_counts dc
LEFT JOIN damage_count_photos dcp ON dc.id = dcp.damage_count_id
WHERE dc.supervisor_id = auth.uid()
GROUP BY dc.id
ORDER BY dc.created_at DESC;
*/

-- ================================
-- NOTES
-- ================================
/*
IMPORTANT NOTES:

1. JSONB Storage:
   - item_counts: {"plastic_chair": 5, "water_sink": 2}
   - text_answers: {"custom_field": "some text"}
   - yes_no_answers: {"has_damage": true}
   - damage_notes: {"plastic_chair": "broken leg"}
   - damage_conditions: {"plastic_chair": "تالف جزئي"}
   - section_photos: {"mechanical_plumbing": ["url1", "url2"]}

2. Categories and Items:
   - mechanical_plumbing: 11 items (chairs, sinks, tanks, pumps, etc.)
   - electrical: 9 items (circuit breakers, panels, heaters, etc.)
   - civil: 1 item (UPVC fabric)
   - safety_security: 7 items (fire equipment, alarms, etc.)
   - air_conditioning: 4 items (cabinet, split, window, package units)

3. Foreign Key Dependencies:
   - Uses existing 'schools' table (with supervisor assignments)
   - Uses existing 'supervisor_schools' table for school assignments  
   - Requires 'auth.users' table (Supabase auth)

4. Security:
   - RLS policies ensure users only see their own data
   - All operations are scoped to authenticated users
   - Foreign key constraints maintain data integrity

5. Performance:
   - Indexes on frequently queried fields
   - JSONB allows flexible querying with GIN indexes if needed
   - Views provide pre-computed statistics

6. Extensibility:
   - JSONB fields allow adding new item types without schema changes
   - Photo table supports multiple photos per section
   - Status field can be extended with new values
*/ 
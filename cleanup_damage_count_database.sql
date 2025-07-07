-- ================================
-- CLEANUP SCRIPT FOR DAMAGE COUNT DATABASE
-- ================================
-- This script removes unnecessary columns and views from damage count tables
-- Run this in your Supabase SQL Editor

-- ================================
-- 1. DROP UNNECESSARY VIEWS
-- ================================

-- Drop the statistics view (this creates the extra table you see)
DROP VIEW IF EXISTS damage_count_statistics CASCADE;

-- Drop the school info view (this creates another extra table you see)
DROP VIEW IF EXISTS damage_counts_with_school_info CASCADE;

-- ================================
-- 2. REMOVE UNNECESSARY COLUMNS FROM MAIN TABLE
-- ================================

-- Remove unused columns from damage_counts table
-- Note: Make sure you backup your data before running these commands!

-- Remove text_answers column
ALTER TABLE damage_counts DROP COLUMN IF EXISTS text_answers CASCADE;

-- Remove yes_no_answers column
ALTER TABLE damage_counts DROP COLUMN IF EXISTS yes_no_answers CASCADE;

-- Remove damage_notes column
ALTER TABLE damage_counts DROP COLUMN IF EXISTS damage_notes CASCADE;

-- Remove damage_conditions column
ALTER TABLE damage_counts DROP COLUMN IF EXISTS damage_conditions CASCADE;

-- ================================
-- 3. VERIFY SIMPLIFIED STRUCTURE
-- ================================

-- Check the simplified table structure
-- You should now only see these columns:
-- - id, school_id, school_name, supervisor_id, status
-- - item_counts (JSONB), section_photos (JSONB)
-- - created_at, updated_at

-- Run this to see the current structure:
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'damage_counts' 
-- ORDER BY ordinal_position;

-- ================================
-- 4. FINAL RESULT
-- ================================

-- After running this script, you should only have:
-- 1. damage_counts (main table with simplified columns)
-- 2. damage_count_photos (photo records table)

-- ================================
-- 5. OPTIONAL: RECREATE SIMPLE VIEWS IF NEEDED
-- ================================

-- If you need a simple statistics view, here's a minimal one:
-- CREATE OR REPLACE VIEW damage_count_summary AS
-- SELECT 
--     school_id,
--     school_name,
--     COUNT(*) as total_counts,
--     COUNT(CASE WHEN status = 'submitted' THEN 1 END) as submitted_counts,
--     MAX(created_at) as last_count_date
-- FROM damage_counts
-- GROUP BY school_id, school_name; 
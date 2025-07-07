-- ================================
-- REFRESH DATABASE SCHEMA CACHE
-- ================================
-- Run this after the column cleanup to refresh Supabase's schema cache

-- Force schema cache refresh by recreating the table's metadata
COMMENT ON TABLE damage_counts IS 'Damage count records - schema updated';

-- Alternative: Use NOTIFY to trigger cache refresh
NOTIFY pgrst, 'reload schema';

-- Check if the problematic columns are gone
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'damage_counts' 
AND column_name IN ('text_answers', 'yes_no_answers', 'damage_notes', 'damage_conditions');

-- This query should return NO ROWS if cleanup was successful

-- Test a simple insert to verify the schema works
-- (This is just for testing - remove after verification)
/*
INSERT INTO damage_counts (
    school_id, 
    school_name, 
    supervisor_id, 
    status,
    item_counts,
    section_photos
) VALUES (
    gen_random_uuid(),
    'Test School',
    auth.uid(),
    'draft',
    '{"test_item": 1}'::jsonb,
    '{}'::jsonb
);

-- Clean up test record
DELETE FROM damage_counts WHERE school_name = 'Test School';
*/ 
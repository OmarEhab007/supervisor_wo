-- ================================
-- FIX DAMAGE COUNT DATABASE SCHEMA
-- ================================
-- Run this script in Supabase SQL Editor to fix the schema mismatch

-- First, let's check what columns currently exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'damage_counts' 
ORDER BY ordinal_position;

-- Now remove the problematic columns that are causing the error
-- These columns were removed from the model but still exist in database

ALTER TABLE damage_counts DROP COLUMN IF EXISTS text_answers CASCADE;
ALTER TABLE damage_counts DROP COLUMN IF EXISTS yes_no_answers CASCADE;  
ALTER TABLE damage_counts DROP COLUMN IF EXISTS damage_notes CASCADE;
ALTER TABLE damage_counts DROP COLUMN IF EXISTS damage_conditions CASCADE;

-- Verify the final structure - should only have these columns:
-- id, school_id, school_name, supervisor_id, status, item_counts, section_photos, created_at, updated_at

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'damage_counts' 
ORDER BY ordinal_position;

-- Expected final columns:
-- id (uuid)
-- school_id (uuid) 
-- school_name (text)
-- supervisor_id (uuid)
-- status (text)
-- item_counts (jsonb)
-- section_photos (jsonb)
-- created_at (timestamp with time zone)
-- updated_at (timestamp with time zone) 
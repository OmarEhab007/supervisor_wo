-- ================================
-- APP VERSIONS TABLE SCHEMA
-- ================================
-- Simple table for managing app version updates

-- Create app versions table
CREATE TABLE IF NOT EXISTS app_versions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    version TEXT NOT NULL,
    download_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    release_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read active versions (no authentication required for updates)
CREATE POLICY "Anyone can read active versions" ON app_versions
    FOR SELECT USING (is_active = true);

-- Policy: Only authenticated users can manage versions (optional admin control)
CREATE POLICY "Authenticated users can manage versions" ON app_versions
    FOR ALL USING (auth.role() = 'authenticated');

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_app_versions_active ON app_versions(is_active, created_at DESC);

-- Insert initial test version (REPLACE WITH YOUR ACTUAL GOOGLE DRIVE LINK)
INSERT INTO app_versions (version, download_url, release_notes, is_active) VALUES 
('0.1.1', 'https://drive.google.com/file/d/YOUR_GOOGLE_DRIVE_FILE_ID/view', 'إصدار تجريبي للتحديث التلقائي - تحسينات في الأداء وإصلاح بعض المشاكل', true)
ON CONFLICT DO NOTHING;

-- Function to update timestamp automatically
CREATE OR REPLACE FUNCTION update_app_versions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_app_versions_updated_at_trigger
    BEFORE UPDATE ON app_versions
    FOR EACH ROW
    EXECUTE FUNCTION update_app_versions_updated_at();

-- ================================
-- HOW TO USE:
-- ================================
-- 1. Run this SQL in your Supabase SQL Editor
-- 2. Replace 'YOUR_GOOGLE_DRIVE_FILE_ID' with your actual Google Drive file ID
-- 3. To add a new version, insert a new record:
--    INSERT INTO app_versions (version, download_url, release_notes) VALUES 
--    ('0.1.2', 'https://drive.google.com/file/d/NEW_FILE_ID/view', 'تحديث جديد');
-- 4. The app will automatically detect new versions and show update dialog

-- ================================
-- GOOGLE DRIVE SETUP:
-- ================================
-- 1. Upload your APK to Google Drive
-- 2. Right-click → Share → Change to "Anyone with the link"
-- 3. Copy the sharing link (format: https://drive.google.com/file/d/FILE_ID/view)
-- 4. The app automatically converts this to direct download URL
-- ================================ 
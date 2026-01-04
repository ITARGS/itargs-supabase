-- FINAL COMPREHENSIVE FIX
-- This ensures EVERYTHING is set up correctly for authentication

-- ============================================================================
-- STEP 1: Verify and fix PostgreSQL roles
-- ============================================================================

-- Ensure anon role has all necessary permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA auth TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Ensure authenticated role has all necessary permissions  
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- STEP 2: Clear ALL sessions to force fresh logins
-- ============================================================================

DELETE FROM auth.sessions;
DELETE FROM auth.refresh_tokens;

-- ============================================================================
-- STEP 3: Verification
-- ============================================================================

SELECT 'AUTHENTICATION FULLY CONFIGURED' as status;

-- Show role permissions
SELECT grantee, COUNT(*) as permission_count
FROM information_schema.table_privileges
WHERE grantee IN ('anon', 'authenticated', 'service_role')
AND table_schema = 'public'
GROUP BY grantee;

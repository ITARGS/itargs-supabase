-- Add automatic cleanup for notifications older than 30 days
-- This policy will automatically delete notifications that are older than 1 month

-- Create a function to delete old notifications
CREATE OR REPLACE FUNCTION delete_old_notifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$;

-- Create a scheduled job to run the cleanup daily
-- Note: This requires pg_cron extension which may need to be enabled by your Supabase admin
-- If pg_cron is not available, you can use a Supabase Edge Function with a cron trigger instead

-- Alternative: Add a Row Level Security policy that filters out old notifications
-- This approach doesn't delete them but makes them invisible to users
CREATE POLICY "Hide notifications older than 30 days"
ON notifications
FOR SELECT
USING (created_at >= NOW() - INTERVAL '30 days');

-- Add a comment explaining the policy
COMMENT ON POLICY "Hide notifications older than 30 days" ON notifications IS 
'Automatically hides notifications older than 30 days from customer view. Actual deletion can be done via scheduled cleanup job.';

-- Check counts
SELECT 
  (SELECT count(*) FROM auth.users) as auth_users_count, 
  (SELECT count(*) FROM public.profiles) as profiles_count;

-- Find users without profiles
SELECT id, email, created_at FROM auth.users 
WHERE id NOT IN (SELECT id FROM public.profiles);

-- Create required roles for Supabase
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
END
$$;

-- Grant postgres role to service roles
GRANT anon TO postgres;
GRANT authenticated TO postgres;
GRANT service_role TO postgres;

-- Create supabase_admin user for postgres-meta
-- Note: postgres-meta will use POSTGRES_USER and POSTGRES_PASSWORD from env
CREATE ROLE IF NOT EXISTS supabase_admin;

-- Create schemas FIRST (before anything tries to use them)
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS realtime;

-- Set schema owners
ALTER SCHEMA auth OWNER TO postgres;
ALTER SCHEMA storage OWNER TO postgres;
ALTER SCHEMA realtime OWNER TO postgres;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA storage TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA realtime TO anon, authenticated, service_role;

-- Grant table permissions on public schema
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schema_migrations table for Realtime (fixes crash)
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version BIGINT PRIMARY KEY,
  inserted_at TIMESTAMP(0) DEFAULT NOW()
);

-- Profiles Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    role TEXT DEFAULT 'customer',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create Profile
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', 'New User')
  );
  
  -- Set role in app_meta_data for JWT claims
  new.raw_app_meta_data = jsonb_set(
    COALESCE(new.raw_app_meta_data, '{}'::jsonb),
    '{role}',
    '"customer"'
  );
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- Site Settings with Mechanical Workstation Theme
CREATE TABLE IF NOT EXISTS public.site_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.site_settings (key, value) VALUES 
('theme_dark_primary_color', '#2EC4C4'),
('theme_dark_secondary_color', '#2EC4C4'),
('theme_dark_accent_color', '#22C55E'),
('theme_dark_background', '#05070A'),
('theme_dark_card', '#0B0F14'),
('theme_dark_muted', '#111827'),
('theme_dark_foreground', '#FFFFFF'),
('theme_dark_muted_foreground', '#9CA3AF'),
('theme_dark_border', '#1F2937'),
('store_name', 'BenchMark El Najar'),
('currency', 'EGP'),
('currency_symbol', 'ج.م')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

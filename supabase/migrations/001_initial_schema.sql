-- CleanSpace Database Schema
-- This migration creates all tables, indexes, and RLS policies
-- Using BIGSERIAL for IDs to match existing Flutter models that use int

-- Profiles table (users)
CREATE TABLE IF NOT EXISTS profiles (
  id BIGSERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL, -- In production, use Supabase Auth instead
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  birthdate TEXT,
  address TEXT,
  bio TEXT,
  gender TEXT,
  user_type TEXT NOT NULL CHECK (user_type IN ('client', 'agency', 'individual_cleaner')),
  agency_name TEXT,
  business_id TEXT,
  services TEXT,
  experience_level TEXT,
  hourly_rate TEXT,
  profile_picture_path TEXT,
  id_verification_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  -- Link to Supabase Auth users (optional)
  auth_user_id TEXT REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Jobs table
CREATE TABLE IF NOT EXISTS jobs (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'booked', 'completed', 'in_progress')),
  posted_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  job_date TIMESTAMPTZ NOT NULL,
  cover_image_url TEXT,
  client_id BIGINT REFERENCES profiles(id) ON DELETE SET NULL,
  agency_id BIGINT REFERENCES profiles(id) ON DELETE SET NULL,
  budget_min REAL,
  budget_max REAL,
  estimated_hours INTEGER,
  required_services TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (client_id IS NOT NULL OR agency_id IS NOT NULL)
);

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id BIGSERIAL PRIMARY KEY,
  job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  client_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  provider_id BIGINT REFERENCES profiles(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  bid_price REAL,
  message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Cleaners table (for agency teams)
CREATE TABLE IF NOT EXISTS cleaners (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  avatar_url TEXT,
  rating REAL NOT NULL DEFAULT 0.0,
  jobs_completed INTEGER NOT NULL DEFAULT 0,
  agency_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cleaner reviews table
CREATE TABLE IF NOT EXISTS cleaner_reviews (
  id BIGSERIAL PRIMARY KEY,
  cleaner_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reviewer_name TEXT NOT NULL,
  rating REAL NOT NULL CHECK (rating >= 0 AND rating <= 5),
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  comment TEXT NOT NULL,
  has_photos BOOLEAN NOT NULL DEFAULT FALSE,
  photo_urls TEXT,
  reviewer_id BIGINT REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cleaning history table
CREATE TABLE IF NOT EXISTS cleaning_history (
  id BIGSERIAL PRIMARY KEY,
  cleaner_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  description TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('office', 'apartment', 'villa', 'house', 'commercial')),
  job_id BIGINT REFERENCES jobs(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User devices table (for FCM tokens)
CREATE TABLE IF NOT EXISTS user_devices (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_jobs_client_id ON jobs(client_id);
CREATE INDEX IF NOT EXISTS idx_jobs_agency_id ON jobs(agency_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_date ON jobs(posted_date DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_job_id ON bookings(job_id);
CREATE INDEX IF NOT EXISTS idx_bookings_client_id ON bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_bookings_provider_id ON bookings(provider_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_cleaners_agency_id ON cleaners(agency_id);
CREATE INDEX IF NOT EXISTS idx_cleaner_reviews_cleaner_id ON cleaner_reviews(cleaner_id);
CREATE INDEX IF NOT EXISTS idx_cleaning_history_cleaner_id ON cleaning_history(cleaner_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(read_at);

-- Row Level Security (RLS) Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaners ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaner_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE cleaning_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can read their own profile"
  ON profiles FOR SELECT
  USING (auth.uid()::text = auth_user_id::text OR auth.uid()::text = id::text::text);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid()::text = auth_user_id::text OR auth.uid()::text = id::text);

-- Jobs policies
CREATE POLICY "Anyone can read active jobs"
  ON jobs FOR SELECT
  USING (is_deleted = FALSE AND status IN ('active', 'in_progress'));

CREATE POLICY "Job owners can read their jobs"
  ON jobs FOR SELECT
  USING (
    auth.uid()::text = client_id::text OR 
    auth.uid()::text = agency_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = client_id)::text = auth.uid()::text OR
    (SELECT auth_user_id FROM profiles WHERE id = agency_id)::text = auth.uid()::text
  );

CREATE POLICY "Users can create jobs"
  ON jobs FOR INSERT
  WITH CHECK (
    auth.uid()::text = client_id::text OR 
    auth.uid()::text = agency_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = client_id)::text = auth.uid()::text OR
    (SELECT auth_user_id FROM profiles WHERE id = agency_id)::text = auth.uid()::text
  );

CREATE POLICY "Job owners can update their jobs"
  ON jobs FOR UPDATE
  USING (
    auth.uid()::text = client_id::text OR 
    auth.uid()::text = agency_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = client_id)::text = auth.uid()::text OR
    (SELECT auth_user_id FROM profiles WHERE id = agency_id)::text = auth.uid()::text
  );

-- Bookings policies
CREATE POLICY "Users can read their bookings"
  ON bookings FOR SELECT
  USING (
    auth.uid()::text = client_id::text OR 
    auth.uid()::text = provider_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = client_id)::text = auth.uid()::text OR
    (SELECT auth_user_id FROM profiles WHERE id = provider_id)::text = auth.uid()::text
  );

CREATE POLICY "Users can create bookings"
  ON bookings FOR INSERT
  WITH CHECK (
    auth.uid()::text = client_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = client_id)::text = auth.uid()::text
  );

CREATE POLICY "Booking owners can update bookings"
  ON bookings FOR UPDATE
  USING (
    auth.uid()::text = client_id::text OR 
    auth.uid()::text = provider_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = client_id)::text = auth.uid()::text OR
    (SELECT auth_user_id FROM profiles WHERE id = provider_id)::text = auth.uid()::text
  );

-- Cleaners policies
CREATE POLICY "Agencies can manage their cleaners"
  ON cleaners FOR ALL
  USING (
    auth.uid()::text = agency_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = agency_id)::text = auth.uid()::text
  );

-- Cleaner reviews policies
CREATE POLICY "Anyone can read reviews"
  ON cleaner_reviews FOR SELECT
  USING (true);

CREATE POLICY "Users can create reviews"
  ON cleaner_reviews FOR INSERT
  WITH CHECK (true);

-- Cleaning history policies
CREATE POLICY "Cleaners can read their history"
  ON cleaning_history FOR SELECT
  USING (
    auth.uid()::text = cleaner_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = cleaner_id)::text = auth.uid()::text
  );

CREATE POLICY "Cleaners can create history"
  ON cleaning_history FOR INSERT
  WITH CHECK (
    auth.uid()::text = cleaner_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = cleaner_id)::text = auth.uid()::text
  );

-- User devices policies
CREATE POLICY "Users can manage their devices"
  ON user_devices FOR ALL
  USING (
    auth.uid()::text = user_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = user_id)::text = auth.uid()::text
  );

-- Notifications policies
CREATE POLICY "Users can read their notifications"
  ON notifications FOR SELECT
  USING (
    auth.uid()::text = user_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = user_id)::text = auth.uid()::text
  );

CREATE POLICY "Users can update their notifications"
  ON notifications FOR UPDATE
  USING (
    auth.uid()::text = user_id::text OR
    (SELECT auth_user_id FROM profiles WHERE id = user_id)::text = auth.uid()::text
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cleaners_updated_at BEFORE UPDATE ON cleaners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


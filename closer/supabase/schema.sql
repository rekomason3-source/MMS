-- ============================================================
-- Closer MVP — Supabase Database Schema
-- Run this in your Supabase SQL editor to initialize the database
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- PROFILES
-- One per user, extends Supabase auth.users
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  timezone TEXT NOT NULL DEFAULT 'America/New_York',
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'plus', 'family', 'coach')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- USER GOALS
-- Daily/weekly targets for nutrition, hydration, fitness
-- ============================================================
CREATE TABLE IF NOT EXISTS user_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  primary_goal TEXT NOT NULL DEFAULT 'general_wellness'
    CHECK (primary_goal IN ('lose_weight','build_muscle','improve_nutrition','build_habits','stay_consistent','postpartum_recovery','general_wellness')),
  daily_calorie_target INT NOT NULL DEFAULT 1800,
  daily_protein_target INT NOT NULL DEFAULT 130,
  daily_carb_target INT NOT NULL DEFAULT 180,
  daily_fat_target INT NOT NULL DEFAULT 60,
  daily_water_target INT NOT NULL DEFAULT 80,    -- oz
  weekly_workout_target INT NOT NULL DEFAULT 4,
  daily_steps_target INT NOT NULL DEFAULT 7500,
  sleep_target NUMERIC(3,1) NOT NULL DEFAULT 7.5, -- hours
  target_weight NUMERIC(5,1),                     -- lbs
  starting_weight NUMERIC(5,1),
  track_weight BOOLEAN NOT NULL DEFAULT TRUE,
  track_measurements BOOLEAN NOT NULL DEFAULT FALSE,
  track_photos BOOLEAN NOT NULL DEFAULT FALSE,
  reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_time TIME DEFAULT '08:00:00',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their goals" ON user_goals USING (auth.uid() = user_id);

-- ============================================================
-- MEALS
-- Logged meals with macros
-- ============================================================
CREATE TABLE IF NOT EXISTS meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  meal_type TEXT NOT NULL DEFAULT 'snack'
    CHECK (meal_type IN ('breakfast','lunch','dinner','snack','drink')),
  calories INT NOT NULL DEFAULT 0,
  protein NUMERIC(6,1) NOT NULL DEFAULT 0,  -- grams
  carbs NUMERIC(6,1) NOT NULL DEFAULT 0,
  fat NUMERIC(6,1) NOT NULL DEFAULT 0,
  notes TEXT,
  photo_url TEXT,
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meals_user_date ON meals(user_id, logged_at);

ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their meals" ON meals USING (auth.uid() = user_id);

-- ============================================================
-- FAVORITE MEALS
-- Quickly re-add previously saved meal templates
-- ============================================================
CREATE TABLE IF NOT EXISTS favorite_meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  meal_type TEXT NOT NULL DEFAULT 'snack',
  calories INT NOT NULL DEFAULT 0,
  protein NUMERIC(6,1) NOT NULL DEFAULT 0,
  carbs NUMERIC(6,1) NOT NULL DEFAULT 0,
  fat NUMERIC(6,1) NOT NULL DEFAULT 0,
  use_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE favorite_meals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their favorites" ON favorite_meals USING (auth.uid() = user_id);

-- ============================================================
-- WORKOUTS
-- ============================================================
CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  workout_type TEXT NOT NULL DEFAULT 'custom'
    CHECK (workout_type IN ('walking','running','strength','cardio','yoga','mobility','cycling','swimming','hiit','custom')),
  title TEXT NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 30,
  calories_burned INT,
  notes TEXT,
  completed BOOLEAN NOT NULL DEFAULT TRUE,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workouts_user_date ON workouts(user_id, logged_at);

ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their workouts" ON workouts USING (auth.uid() = user_id);

-- ============================================================
-- HYDRATION LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS hydration_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount_oz INT NOT NULL,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hydration_user_date ON hydration_logs(user_id, logged_at);

ALTER TABLE hydration_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their hydration logs" ON hydration_logs USING (auth.uid() = user_id);

-- ============================================================
-- WEIGHT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS weight_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  weight_lbs NUMERIC(5,1) NOT NULL,
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_weight_user_date ON weight_logs(user_id, logged_at);

ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their weight logs" ON weight_logs USING (auth.uid() = user_id);

-- ============================================================
-- MEASUREMENT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS measurement_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  waist_inches NUMERIC(4,1),
  hips_inches NUMERIC(4,1),
  chest_inches NUMERIC(4,1),
  arm_inches NUMERIC(4,1),
  thigh_inches NUMERIC(4,1),
  body_fat_estimate NUMERIC(4,1),
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE measurement_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their measurements" ON measurement_logs USING (auth.uid() = user_id);

-- ============================================================
-- PROGRESS PHOTOS
-- ============================================================
CREATE TABLE IF NOT EXISTS progress_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their photos" ON progress_photos USING (auth.uid() = user_id);

-- ============================================================
-- MOOD LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS mood_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  mood SMALLINT NOT NULL CHECK (mood BETWEEN 1 AND 5),
  energy SMALLINT NOT NULL CHECK (energy BETWEEN 1 AND 5),
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their mood logs" ON mood_logs USING (auth.uid() = user_id);

-- ============================================================
-- STREAKS
-- Current and longest streak per type
-- ============================================================
CREATE TABLE IF NOT EXISTS streaks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  streak_type TEXT NOT NULL
    CHECK (streak_type IN ('daily_log','protein_goal','hydration_goal','workout','weekly_review')),
  current_count INT NOT NULL DEFAULT 0,
  longest_count INT NOT NULL DEFAULT 0,
  last_logged_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, streak_type)
);

ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their streaks" ON streaks USING (auth.uid() = user_id);

-- ============================================================
-- BADGES (global definitions)
-- ============================================================
CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category TEXT NOT NULL
    CHECK (category IN ('logging','nutrition','hydration','fitness','consistency','progress','support','milestone')),
  requirement_type TEXT NOT NULL,
  requirement_value INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- USER BADGES (earned)
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  badge_id UUID REFERENCES badges(id) NOT NULL,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own badges" ON user_badges FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- SUPPORTER RELATIONSHIPS
-- Controls who can see whose data
-- ============================================================
CREATE TABLE IF NOT EXISTS supporter_relationships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  primary_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  supporter_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  invite_email TEXT NOT NULL,
  invite_token TEXT NOT NULL UNIQUE DEFAULT uuid_generate_v4()::TEXT,
  relationship_type TEXT NOT NULL DEFAULT 'friend'
    CHECK (relationship_type IN ('partner','spouse','friend','family','coach')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','accepted','declined','revoked')),
  can_view_dashboard BOOLEAN NOT NULL DEFAULT TRUE,
  can_send_encouragement BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE supporter_relationships ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Primary user manages relationships" ON supporter_relationships
  USING (auth.uid() = primary_user_id OR auth.uid() = supporter_user_id);

-- ============================================================
-- ENCOURAGEMENT MESSAGES
-- Sent from supporter to primary user
-- ============================================================
CREATE TABLE IF NOT EXISTS encouragement_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  receiver_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'encouragement'
    CHECK (message_type IN ('encouragement','celebration','check_in','milestone_react')),
  reaction TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE encouragement_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see their messages" ON encouragement_messages
  USING (auth.uid() = sender_user_id OR auth.uid() = receiver_user_id);

-- ============================================================
-- WEEKLY SUMMARIES
-- Auto-generated + reviewed each week
-- ============================================================
CREATE TABLE IF NOT EXISTS weekly_summaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,
  avg_calories INT,
  avg_protein INT,
  avg_water_oz INT,
  workouts_completed INT,
  avg_sleep_hours NUMERIC(3,1),
  weight_change_lbs NUMERIC(4,1),
  best_streak INT,
  weekly_wins TEXT[] DEFAULT '{}',
  next_week_focus TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);

ALTER TABLE weekly_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their weekly summaries" ON weekly_summaries USING (auth.uid() = user_id);

-- ============================================================
-- NOTIFICATION PREFERENCES
-- ============================================================
CREATE TABLE IF NOT EXISTS notification_prefs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  morning_reminder BOOLEAN NOT NULL DEFAULT TRUE,
  morning_reminder_time TIME NOT NULL DEFAULT '08:00:00',
  evening_check_in BOOLEAN NOT NULL DEFAULT FALSE,
  evening_check_in_time TIME NOT NULL DEFAULT '20:00:00',
  weekly_review_reminder BOOLEAN NOT NULL DEFAULT TRUE,
  supporter_messages BOOLEAN NOT NULL DEFAULT TRUE,
  milestone_alerts BOOLEAN NOT NULL DEFAULT TRUE,
  streak_alerts BOOLEAN NOT NULL DEFAULT TRUE,
  push_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  email_enabled BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE notification_prefs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their notification prefs" ON notification_prefs USING (auth.uid() = user_id);

-- ============================================================
-- SUBSCRIPTION PLACEHOLDER
-- Structured for future Stripe integration
-- ============================================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','plus','family','coach')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','trialing','cancelled','past_due')),
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own subscription" ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- TRIGGERS — Auto-update updated_at timestamps
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER user_goals_updated_at BEFORE UPDATE ON user_goals FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER streaks_updated_at BEFORE UPDATE ON streaks FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER supporter_relationships_updated_at BEFORE UPDATE ON supporter_relationships FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- TRIGGER — Auto-create profile on signup
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (user_id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'));

  INSERT INTO user_goals (user_id) VALUES (NEW.id);
  INSERT INTO notification_prefs (user_id) VALUES (NEW.id);
  INSERT INTO subscriptions (user_id) VALUES (NEW.id);

  -- Initialize all streak types
  INSERT INTO streaks (user_id, streak_type) VALUES
    (NEW.id, 'daily_log'),
    (NEW.id, 'protein_goal'),
    (NEW.id, 'hydration_goal'),
    (NEW.id, 'workout'),
    (NEW.id, 'weekly_review');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- SEED: Badge definitions
-- ============================================================
INSERT INTO badges (key, title, description, icon, category, requirement_type, requirement_value) VALUES
  ('first_log', 'First Step', 'Logged your first meal', '🌱', 'logging', 'meal_count', 1),
  ('log_3_days', 'Getting Started', '3 days of consistent logging', '📝', 'logging', 'log_streak', 3),
  ('log_7_days', 'Week One', '7-day logging streak', '⭐', 'logging', 'log_streak', 7),
  ('log_14_days', 'Two Weeks Strong', '14-day logging streak', '💫', 'logging', 'log_streak', 14),
  ('log_30_days', 'One Month', '30-day logging streak', '🔥', 'logging', 'log_streak', 30),
  ('protein_first', 'Protein First', 'Hit your protein goal', '💪', 'nutrition', 'protein_goal_hit', 1),
  ('protein_week', 'Protein Week', 'Hit protein goal 7 days in a row', '🥩', 'nutrition', 'protein_goal_streak', 7),
  ('hydrated', 'Well Hydrated', 'Hit your water goal', '💧', 'hydration', 'hydration_goal_hit', 1),
  ('hydration_week', 'Hydration Habit', 'Hit water goal 7 days in a row', '🌊', 'hydration', 'hydration_goal_streak', 7),
  ('first_workout', 'Moving', 'Logged your first workout', '🏃', 'fitness', 'workout_count', 1),
  ('workout_10', 'Ten Sessions', 'Completed 10 workouts', '🏋️', 'fitness', 'workout_count', 10),
  ('workout_50', 'Fifty Strong', 'Completed 50 workouts', '🥇', 'fitness', 'workout_count', 50),
  ('first_weight', 'Starting Line', 'Logged your starting weight', '📊', 'progress', 'weight_log_count', 1),
  ('progress_photo', 'Captured', 'Added a progress photo', '📸', 'progress', 'photo_count', 1),
  ('weekly_review_1', 'Reflective', 'Completed your first weekly review', '🔍', 'consistency', 'weekly_review_count', 1),
  ('weekly_review_4', 'Month of Reflection', 'Completed 4 weekly reviews', '📅', 'consistency', 'weekly_review_count', 4),
  ('invited_supporter', 'Not Alone', 'Invited a supporter', '🤝', 'support', 'supporter_count', 1)
ON CONFLICT (key) DO NOTHING;

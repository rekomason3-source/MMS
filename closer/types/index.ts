// ============================================================
// Closer MVP — Core TypeScript Types
// ============================================================

// --- Users & Auth ---
export interface User {
  id: string
  email: string
  created_at: string
  updated_at: string
}

export interface Profile {
  id: string
  user_id: string
  full_name: string
  display_name?: string
  avatar_url?: string
  bio?: string
  timezone: string
  onboarding_completed: boolean
  plan: SubscriptionPlan
  created_at: string
  updated_at: string
}

export type SubscriptionPlan = 'free' | 'plus' | 'family' | 'coach'

// --- Goals & Settings ---
export interface UserGoals {
  id: string
  user_id: string
  primary_goal: PrimaryGoal
  daily_calorie_target: number
  daily_protein_target: number   // grams
  daily_carb_target: number      // grams
  daily_fat_target: number       // grams
  daily_water_target: number     // oz
  weekly_workout_target: number
  daily_steps_target: number
  sleep_target: number           // hours
  target_weight?: number         // lbs
  starting_weight?: number       // lbs
  track_weight: boolean
  track_measurements: boolean
  track_photos: boolean
  reminder_enabled: boolean
  reminder_time?: string
  created_at: string
  updated_at: string
}

export type PrimaryGoal =
  | 'lose_weight'
  | 'build_muscle'
  | 'improve_nutrition'
  | 'build_habits'
  | 'stay_consistent'
  | 'postpartum_recovery'
  | 'general_wellness'

// --- Meals & Nutrition ---
export interface Meal {
  id: string
  user_id: string
  title: string
  meal_type: MealType
  calories: number
  protein: number    // grams
  carbs: number      // grams
  fat: number        // grams
  notes?: string
  photo_url?: string
  is_favorite: boolean
  logged_at: string
  created_at: string
}

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'drink'

export interface FavoriteMeal {
  id: string
  user_id: string
  title: string
  meal_type: MealType
  calories: number
  protein: number
  carbs: number
  fat: number
  use_count: number
  created_at: string
}

// --- Workouts ---
export interface Workout {
  id: string
  user_id: string
  workout_type: WorkoutType
  title: string
  duration_minutes: number
  calories_burned?: number
  notes?: string
  completed: boolean
  logged_at: string
  created_at: string
}

export type WorkoutType =
  | 'walking'
  | 'running'
  | 'strength'
  | 'cardio'
  | 'yoga'
  | 'mobility'
  | 'cycling'
  | 'swimming'
  | 'hiit'
  | 'custom'

// --- Hydration ---
export interface HydrationLog {
  id: string
  user_id: string
  amount_oz: number
  logged_at: string
  created_at: string
}

// --- Weight & Measurements ---
export interface WeightLog {
  id: string
  user_id: string
  weight_lbs: number
  notes?: string
  logged_at: string
  created_at: string
}

export interface MeasurementLog {
  id: string
  user_id: string
  waist_inches?: number
  hips_inches?: number
  chest_inches?: number
  arm_inches?: number
  thigh_inches?: number
  body_fat_estimate?: number
  notes?: string
  logged_at: string
  created_at: string
}

export interface ProgressPhoto {
  id: string
  user_id: string
  photo_url: string
  notes?: string
  logged_at: string
  created_at: string
}

// --- Mood / Energy ---
export interface MoodLog {
  id: string
  user_id: string
  mood: MoodLevel
  energy: EnergyLevel
  notes?: string
  logged_at: string
  created_at: string
}

export type MoodLevel = 1 | 2 | 3 | 4 | 5
export type EnergyLevel = 1 | 2 | 3 | 4 | 5

// --- Streaks ---
export interface Streak {
  id: string
  user_id: string
  streak_type: StreakType
  current_count: number
  longest_count: number
  last_logged_date: string
  created_at: string
  updated_at: string
}

export type StreakType =
  | 'daily_log'
  | 'protein_goal'
  | 'hydration_goal'
  | 'workout'
  | 'weekly_review'

// --- Badges & Milestones ---
export interface Badge {
  id: string
  key: string
  title: string
  description: string
  icon: string
  category: BadgeCategory
  requirement_type: string
  requirement_value: number
}

export type BadgeCategory =
  | 'logging'
  | 'nutrition'
  | 'hydration'
  | 'fitness'
  | 'consistency'
  | 'progress'
  | 'support'
  | 'milestone'

export interface UserBadge {
  id: string
  user_id: string
  badge_id: string
  badge: Badge
  earned_at: string
}

// --- Supporter Relationships ---
export interface SupporterRelationship {
  id: string
  primary_user_id: string
  supporter_user_id?: string
  invite_email: string
  invite_token: string
  relationship_type: RelationshipType
  status: InviteStatus
  can_view_dashboard: boolean
  can_send_encouragement: boolean
  created_at: string
  updated_at: string
}

export type RelationshipType = 'partner' | 'spouse' | 'friend' | 'family' | 'coach'
export type InviteStatus = 'pending' | 'accepted' | 'declined' | 'revoked'

// --- Encouragement Messages ---
export interface EncouragementMessage {
  id: string
  sender_user_id: string
  receiver_user_id: string
  message: string
  message_type: MessageType
  reaction?: string
  created_at: string
}

export type MessageType = 'encouragement' | 'celebration' | 'check_in' | 'milestone_react'

// --- Weekly Summaries ---
export interface WeeklySummary {
  id: string
  user_id: string
  week_start: string
  week_end: string
  avg_calories: number
  avg_protein: number
  avg_water_oz: number
  workouts_completed: number
  avg_sleep_hours: number
  weight_change_lbs?: number
  best_streak: number
  weekly_wins: string[]
  next_week_focus: string
  reviewed_at?: string
  created_at: string
}

// --- Notification Preferences ---
export interface NotificationPrefs {
  id: string
  user_id: string
  morning_reminder: boolean
  morning_reminder_time: string
  evening_check_in: boolean
  evening_check_in_time: string
  weekly_review_reminder: boolean
  supporter_messages: boolean
  milestone_alerts: boolean
  streak_alerts: boolean
  push_enabled: boolean
  email_enabled: boolean
}

// --- App UI State ---
export interface DailyStats {
  date: string
  calories_consumed: number
  protein_consumed: number
  carbs_consumed: number
  fat_consumed: number
  water_oz: number
  workouts_completed: number
  sleep_hours?: number
  weight?: number
  mood?: MoodLevel
  energy?: EnergyLevel
  logging_streak: number
}

export interface MacroProgress {
  calories: { current: number; target: number }
  protein: { current: number; target: number }
  carbs: { current: number; target: number }
  fat: { current: number; target: number }
}

// --- Onboarding ---
export interface OnboardingData {
  full_name: string
  primary_goal: PrimaryGoal
  starting_weight?: number
  target_weight?: number
  daily_calorie_target: number
  daily_protein_target: number
  daily_water_target: number
  weekly_workout_target: number
  track_weight: boolean
  track_measurements: boolean
  invite_supporter: boolean
  supporter_email?: string
  supporter_relationship?: RelationshipType
  reminder_enabled: boolean
}

// --- Chart Data ---
export interface WeightDataPoint {
  date: string
  weight: number
}

export interface MacroDataPoint {
  date: string
  calories: number
  protein: number
  carbs: number
  fat: number
}

export interface WaterDataPoint {
  date: string
  water_oz: number
  target: number
}

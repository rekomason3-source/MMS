// ============================================================
// Closer MVP — Mock / Seed Data
// Used for demo mode when Supabase is not configured
// ============================================================

import { format, subDays } from 'date-fns'
import type {
  Profile,
  UserGoals,
  Meal,
  Workout,
  HydrationLog,
  WeightLog,
  MoodLog,
  Streak,
  UserBadge,
  WeeklySummary,
  DailyStats,
  WeightDataPoint,
  MacroDataPoint,
} from '@/types'

const today = new Date()
const fmt = (d: Date) => format(d, 'yyyy-MM-dd')

export const MOCK_PROFILE: Profile = {
  id: 'mock-user-1',
  user_id: 'mock-user-1',
  full_name: 'Sarah Johnson',
  display_name: 'Sarah',
  avatar_url: undefined,
  bio: 'Working on feeling my best',
  timezone: 'America/Chicago',
  onboarding_completed: true,
  plan: 'free',
  created_at: '2024-01-15T00:00:00Z',
  updated_at: '2024-01-15T00:00:00Z',
}

export const MOCK_GOALS: UserGoals = {
  id: 'mock-goals-1',
  user_id: 'mock-user-1',
  primary_goal: 'lose_weight',
  daily_calorie_target: 1800,
  daily_protein_target: 130,
  daily_carb_target: 180,
  daily_fat_target: 60,
  daily_water_target: 80,
  weekly_workout_target: 4,
  daily_steps_target: 7500,
  sleep_target: 7.5,
  target_weight: 145,
  starting_weight: 168,
  track_weight: true,
  track_measurements: false,
  track_photos: false,
  reminder_enabled: true,
  reminder_time: '08:00',
  created_at: '2024-01-15T00:00:00Z',
  updated_at: '2024-01-15T00:00:00Z',
}

export const MOCK_TODAY_MEALS: Meal[] = [
  {
    id: 'meal-1',
    user_id: 'mock-user-1',
    title: 'Greek Yogurt with Berries',
    meal_type: 'breakfast',
    calories: 220,
    protein: 18,
    carbs: 28,
    fat: 4,
    notes: 'Added honey',
    is_favorite: true,
    logged_at: format(today, "yyyy-MM-dd'T'08:15:00"),
    created_at: format(today, "yyyy-MM-dd'T'08:15:00"),
  },
  {
    id: 'meal-2',
    user_id: 'mock-user-1',
    title: 'Grilled Chicken Salad',
    meal_type: 'lunch',
    calories: 380,
    protein: 42,
    carbs: 18,
    fat: 14,
    is_favorite: false,
    logged_at: format(today, "yyyy-MM-dd'T'12:30:00"),
    created_at: format(today, "yyyy-MM-dd'T'12:30:00"),
  },
  {
    id: 'meal-3',
    user_id: 'mock-user-1',
    title: 'Protein Bar',
    meal_type: 'snack',
    calories: 200,
    protein: 20,
    carbs: 22,
    fat: 7,
    is_favorite: true,
    logged_at: format(today, "yyyy-MM-dd'T'15:00:00"),
    created_at: format(today, "yyyy-MM-dd'T'15:00:00"),
  },
]

export const MOCK_TODAY_WORKOUTS: Workout[] = [
  {
    id: 'workout-1',
    user_id: 'mock-user-1',
    workout_type: 'walking',
    title: 'Morning Walk',
    duration_minutes: 30,
    calories_burned: 150,
    notes: 'Neighborhood loop',
    completed: true,
    logged_at: format(today, "yyyy-MM-dd'T'07:00:00"),
    created_at: format(today, "yyyy-MM-dd'T'07:00:00"),
  },
]

export const MOCK_TODAY_WATER: HydrationLog[] = [
  { id: 'water-1', user_id: 'mock-user-1', amount_oz: 16, logged_at: format(today, "yyyy-MM-dd'T'07:30:00"), created_at: '' },
  { id: 'water-2', user_id: 'mock-user-1', amount_oz: 16, logged_at: format(today, "yyyy-MM-dd'T'10:00:00"), created_at: '' },
  { id: 'water-3', user_id: 'mock-user-1', amount_oz: 16, logged_at: format(today, "yyyy-MM-dd'T'13:00:00"), created_at: '' },
]

export const MOCK_MOOD: MoodLog = {
  id: 'mood-1',
  user_id: 'mock-user-1',
  mood: 4,
  energy: 3,
  logged_at: format(today, "yyyy-MM-dd'T'09:00:00"),
  created_at: '',
}

export const MOCK_STREAKS: Streak[] = [
  { id: 's1', user_id: 'mock-user-1', streak_type: 'daily_log', current_count: 9, longest_count: 14, last_logged_date: fmt(today), created_at: '', updated_at: '' },
  { id: 's2', user_id: 'mock-user-1', streak_type: 'protein_goal', current_count: 5, longest_count: 9, last_logged_date: fmt(today), created_at: '', updated_at: '' },
  { id: 's3', user_id: 'mock-user-1', streak_type: 'hydration_goal', current_count: 3, longest_count: 7, last_logged_date: fmt(yesterday()), created_at: '', updated_at: '' },
  { id: 's4', user_id: 'mock-user-1', streak_type: 'workout', current_count: 2, longest_count: 5, last_logged_date: fmt(today), created_at: '', updated_at: '' },
]

export const MOCK_BADGES: UserBadge[] = [
  { id: 'ub1', user_id: 'mock-user-1', badge_id: 'first_log', badge: { id: 'b1', key: 'first_log', title: 'First Step', description: 'Logged your first meal', icon: '🌱', category: 'logging', requirement_type: 'meal_count', requirement_value: 1 }, earned_at: '2024-01-15T00:00:00Z' },
  { id: 'ub2', user_id: 'mock-user-1', badge_id: 'log_7_days', badge: { id: 'b2', key: 'log_7_days', title: 'Week One', description: '7-day logging streak', icon: '⭐', category: 'logging', requirement_type: 'log_streak', requirement_value: 7 }, earned_at: '2024-01-22T00:00:00Z' },
  { id: 'ub3', user_id: 'mock-user-1', badge_id: 'protein_first', badge: { id: 'b3', key: 'protein_first', title: 'Protein First', description: 'Hit your protein goal', icon: '💪', category: 'nutrition', requirement_type: 'protein_goal_hit', requirement_value: 1 }, earned_at: '2024-01-16T00:00:00Z' },
  { id: 'ub4', user_id: 'mock-user-1', badge_id: 'first_workout', badge: { id: 'b4', key: 'first_workout', title: 'Moving', description: 'Logged your first workout', icon: '🏃', category: 'fitness', requirement_type: 'workout_count', requirement_value: 1 }, earned_at: '2024-01-15T00:00:00Z' },
  { id: 'ub5', user_id: 'mock-user-1', badge_id: 'hydrated', badge: { id: 'b5', key: 'hydrated', title: 'Well Hydrated', description: 'Hit your water goal', icon: '💧', category: 'hydration', requirement_type: 'hydration_goal_hit', requirement_value: 1 }, earned_at: '2024-01-17T00:00:00Z' },
  { id: 'ub6', user_id: 'mock-user-1', badge_id: 'weekly_review_1', badge: { id: 'b6', key: 'weekly_review_1', title: 'Reflective', description: 'Completed your first weekly review', icon: '🔍', category: 'consistency', requirement_type: 'weekly_review_count', requirement_value: 1 }, earned_at: '2024-01-21T00:00:00Z' },
]

// Weight trend — 30 days
export const MOCK_WEIGHT_DATA: WeightDataPoint[] = Array.from({ length: 30 }, (_, i) => ({
  date: fmt(subDays(today, 29 - i)),
  weight: 168 - (i * 0.12) + (Math.random() * 0.6 - 0.3),
})).map(d => ({ ...d, weight: parseFloat(d.weight.toFixed(1)) }))

// Macro trend — 14 days
export const MOCK_MACRO_DATA: MacroDataPoint[] = Array.from({ length: 14 }, (_, i) => ({
  date: fmt(subDays(today, 13 - i)),
  calories: Math.round(1600 + Math.random() * 400),
  protein: Math.round(110 + Math.random() * 40),
  carbs: Math.round(150 + Math.random() * 60),
  fat: Math.round(50 + Math.random() * 20),
}))

export const MOCK_WEEKLY_SUMMARY: WeeklySummary = {
  id: 'ws1',
  user_id: 'mock-user-1',
  week_start: fmt(subDays(today, 6)),
  week_end: fmt(today),
  avg_calories: 1720,
  avg_protein: 118,
  avg_water_oz: 68,
  workouts_completed: 3,
  avg_sleep_hours: 7.1,
  weight_change_lbs: -0.8,
  best_streak: 7,
  weekly_wins: [
    'Hit protein goal 5 out of 7 days',
    'Completed 3 workouts',
    'Drank more water than last week',
  ],
  next_week_focus: 'Hit protein goal daily and add one more workout session',
  reviewed_at: undefined,
  created_at: '',
}

function yesterday() {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return d
}

// Compute today's totals from mock meals/water
export function computeTodayStats(goals: UserGoals): DailyStats {
  const calories = MOCK_TODAY_MEALS.reduce((s, m) => s + m.calories, 0)
  const protein = MOCK_TODAY_MEALS.reduce((s, m) => s + m.protein, 0)
  const carbs = MOCK_TODAY_MEALS.reduce((s, m) => s + m.carbs, 0)
  const fat = MOCK_TODAY_MEALS.reduce((s, m) => s + m.fat, 0)
  const water = MOCK_TODAY_WATER.reduce((s, w) => s + w.amount_oz, 0)

  return {
    date: fmt(today),
    calories_consumed: calories,
    protein_consumed: protein,
    carbs_consumed: carbs,
    fat_consumed: fat,
    water_oz: water,
    workouts_completed: MOCK_TODAY_WORKOUTS.length,
    sleep_hours: 7.2,
    weight: MOCK_WEIGHT_DATA[MOCK_WEIGHT_DATA.length - 1].weight,
    mood: MOCK_MOOD.mood,
    energy: MOCK_MOOD.energy,
    logging_streak: 9,
  }
}

// ============================================================
// Closer MVP — App Constants
// ============================================================

export const APP_NAME = 'Closer'
export const APP_TAGLINE = 'Progress without pressure. Support without shame.'
export const APP_DESCRIPTION =
  'A private accountability app for people who want to reach their health goals with support, not judgment.'

// Default goal targets
export const DEFAULT_CALORIES = 1800
export const DEFAULT_PROTEIN = 130   // grams
export const DEFAULT_CARBS = 180     // grams
export const DEFAULT_FAT = 60        // grams
export const DEFAULT_WATER = 80      // oz (~2.4L)
export const DEFAULT_WORKOUTS = 4    // per week
export const DEFAULT_SLEEP = 7.5     // hours
export const DEFAULT_STEPS = 7500

// Macro calorie ratios (for target calculation)
export const PROTEIN_CAL_PER_GRAM = 4
export const CARB_CAL_PER_GRAM = 4
export const FAT_CAL_PER_GRAM = 9

// Subscription plan features
export const PLAN_LIMITS = {
  free: {
    history_days: 30,
    supporters: 0,
    progress_photos: 5,
    ai_features: false,
    advanced_charts: false,
    export: false,
  },
  plus: {
    history_days: 365,
    supporters: 2,
    progress_photos: 50,
    ai_features: false,
    advanced_charts: true,
    export: true,
  },
  family: {
    history_days: 365,
    supporters: 5,
    progress_photos: 200,
    ai_features: false,
    advanced_charts: true,
    export: true,
  },
  coach: {
    history_days: 730,
    supporters: 20,
    progress_photos: 500,
    ai_features: true,
    advanced_charts: true,
    export: true,
  },
}

// Badge definitions — unlockable achievements
export const BADGE_DEFINITIONS = [
  // Logging badges
  { key: 'first_log', title: 'First Step', description: 'Logged your first meal', icon: '🌱', category: 'logging', requirement_type: 'meal_count', requirement_value: 1 },
  { key: 'log_3_days', title: 'Getting Started', description: '3 days of consistent logging', icon: '📝', category: 'logging', requirement_type: 'log_streak', requirement_value: 3 },
  { key: 'log_7_days', title: 'Week One', description: '7-day logging streak', icon: '⭐', category: 'logging', requirement_type: 'log_streak', requirement_value: 7 },
  { key: 'log_14_days', title: 'Two Weeks Strong', description: '14-day logging streak', icon: '💫', category: 'logging', requirement_type: 'log_streak', requirement_value: 14 },
  { key: 'log_30_days', title: 'One Month', description: '30-day logging streak', icon: '🔥', category: 'logging', requirement_type: 'log_streak', requirement_value: 30 },
  // Nutrition badges
  { key: 'protein_first', title: 'Protein First', description: 'Hit your protein goal', icon: '💪', category: 'nutrition', requirement_type: 'protein_goal_hit', requirement_value: 1 },
  { key: 'protein_week', title: 'Protein Week', description: 'Hit protein goal 7 days', icon: '🥩', category: 'nutrition', requirement_type: 'protein_goal_streak', requirement_value: 7 },
  // Hydration badges
  { key: 'hydrated', title: 'Well Hydrated', description: 'Hit your water goal', icon: '💧', category: 'hydration', requirement_type: 'hydration_goal_hit', requirement_value: 1 },
  { key: 'hydration_week', title: 'Hydration Habit', description: 'Hit water goal 7 days', icon: '🌊', category: 'hydration', requirement_type: 'hydration_goal_streak', requirement_value: 7 },
  // Fitness badges
  { key: 'first_workout', title: 'Moving', description: 'Logged your first workout', icon: '🏃', category: 'fitness', requirement_type: 'workout_count', requirement_value: 1 },
  { key: 'workout_10', title: 'Ten Sessions', description: 'Completed 10 workouts', icon: '🏋️', category: 'fitness', requirement_type: 'workout_count', requirement_value: 10 },
  { key: 'workout_50', title: 'Fifty Strong', description: 'Completed 50 workouts', icon: '🥇', category: 'fitness', requirement_type: 'workout_count', requirement_value: 50 },
  // Progress badges
  { key: 'first_weight', title: 'Starting Line', description: 'Logged your starting weight', icon: '📊', category: 'progress', requirement_type: 'weight_log_count', requirement_value: 1 },
  { key: 'progress_photo', title: 'Captured', description: 'Added a progress photo', icon: '📸', category: 'progress', requirement_type: 'photo_count', requirement_value: 1 },
  // Consistency badges
  { key: 'weekly_review_1', title: 'Reflective', description: 'Completed your first weekly review', icon: '🔍', category: 'consistency', requirement_type: 'weekly_review_count', requirement_value: 1 },
  { key: 'weekly_review_4', title: 'Month of Reflection', description: 'Completed 4 weekly reviews', icon: '📅', category: 'consistency', requirement_type: 'weekly_review_count', requirement_value: 4 },
  // Support badges
  { key: 'invited_supporter', title: 'Not Alone', description: 'Invited a supporter', icon: '🤝', category: 'support', requirement_type: 'supporter_count', requirement_value: 1 },
]

// Water amount quick-add options (oz)
export const WATER_QUICK_ADD = [8, 12, 16, 20, 24, 32]

// Workout duration quick-select (minutes)
export const WORKOUT_DURATIONS = [15, 20, 30, 45, 60, 90]

// Common workout types for quick logging
export const WORKOUT_TYPES = [
  { value: 'walking', label: 'Walking', emoji: '🚶' },
  { value: 'running', label: 'Running', emoji: '🏃' },
  { value: 'strength', label: 'Strength', emoji: '🏋️' },
  { value: 'cardio', label: 'Cardio', emoji: '❤️' },
  { value: 'yoga', label: 'Yoga', emoji: '🧘' },
  { value: 'mobility', label: 'Mobility', emoji: '🤸' },
  { value: 'cycling', label: 'Cycling', emoji: '🚴' },
  { value: 'swimming', label: 'Swimming', emoji: '🏊' },
  { value: 'hiit', label: 'HIIT', emoji: '⚡' },
  { value: 'custom', label: 'Custom', emoji: '✏️' },
]

export const MEAL_TYPES = [
  { value: 'breakfast', label: 'Breakfast', emoji: '🌅' },
  { value: 'lunch', label: 'Lunch', emoji: '☀️' },
  { value: 'dinner', label: 'Dinner', emoji: '🌙' },
  { value: 'snack', label: 'Snack', emoji: '🍎' },
  { value: 'drink', label: 'Drink', emoji: '🥤' },
]

export const PRIMARY_GOALS = [
  { value: 'lose_weight', label: 'Lose weight sustainably', emoji: '📉' },
  { value: 'build_muscle', label: 'Build strength & muscle', emoji: '💪' },
  { value: 'improve_nutrition', label: 'Improve my nutrition', emoji: '🥗' },
  { value: 'build_habits', label: 'Build healthy habits', emoji: '📆' },
  { value: 'stay_consistent', label: 'Stay consistent', emoji: '🎯' },
  { value: 'postpartum_recovery', label: 'Postpartum wellness', emoji: '🌸' },
  { value: 'general_wellness', label: 'General wellness', emoji: '✨' },
]

export const RELATIONSHIP_TYPES = [
  { value: 'partner', label: 'Partner / Significant Other' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'friend', label: 'Friend' },
  { value: 'family', label: 'Family Member' },
  { value: 'coach', label: 'Coach or Trainer' },
]

// Mood options
export const MOOD_OPTIONS = [
  { value: 1, label: 'Struggling', emoji: '😔' },
  { value: 2, label: 'Okay', emoji: '😐' },
  { value: 3, label: 'Good', emoji: '🙂' },
  { value: 4, label: 'Great', emoji: '😊' },
  { value: 5, label: 'Amazing', emoji: '🤩' },
]

export const ENERGY_OPTIONS = [
  { value: 1, label: 'Drained', emoji: '🪫' },
  { value: 2, label: 'Low', emoji: '😴' },
  { value: 3, label: 'Okay', emoji: '⚡' },
  { value: 4, label: 'Energized', emoji: '✨' },
  { value: 5, label: 'Fired Up', emoji: '🔥' },
]

// Monetization plan details (for future upgrade prompt)
export const PRICING = {
  plus: { monthly: 9.99, annual: 79.99, label: 'Closer Plus' },
  family: { monthly: 16.99, annual: 139.99, label: 'Family Plan' },
  coach: { monthly: 29.99, annual: 239.99, label: 'Coach Plan' },
}

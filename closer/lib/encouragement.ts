// ============================================================
// Closer MVP — Encouragement Engine
// A core product differentiator: supportive, shame-free messages
// ============================================================

export type EncouragementTrigger =
  | 'first_meal_logged'
  | 'protein_goal_hit'
  | 'hydration_goal_hit'
  | 'workout_logged'
  | 'streak_3_day'
  | 'streak_7_day'
  | 'streak_14_day'
  | 'streak_30_day'
  | 'weekly_review_completed'
  | 'returning_after_gap'
  | 'weight_logged'
  | 'milestone_earned'
  | 'general_checkin'
  | 'morning_greeting'
  | 'evening_checkin'

interface EncouragementSet {
  messages: string[]
  style: 'celebration' | 'supportive' | 'gentle' | 'motivating'
}

// Core message library — voice: hopeful, warm, practical, shame-free
const ENCOURAGEMENT_LIBRARY: Record<EncouragementTrigger, EncouragementSet> = {
  first_meal_logged: {
    style: 'celebration',
    messages: [
      "You showed up today. That's how it starts.",
      "First log of the day. You're building something real.",
      "One small action. That's all it takes to begin.",
      "Every great streak starts with a single entry. Well done.",
    ],
  },
  protein_goal_hit: {
    style: 'celebration',
    messages: [
      "Protein goal reached. Your body is thanking you right now.",
      "Protein locked in. That's how you build and recover.",
      "Hitting protein is a big deal. You did it today.",
      "You fueled yourself well today. Protein goal: done.",
    ],
  },
  hydration_goal_hit: {
    style: 'celebration',
    messages: [
      "Hydration goal hit. Your energy and focus will show it.",
      "You're well hydrated today. That matters more than most people realize.",
      "Water goal achieved. Simple, powerful, consistent.",
      "Staying hydrated is one of the best things you can do. You did it.",
    ],
  },
  workout_logged: {
    style: 'motivating',
    messages: [
      "Movement logged. You're one step closer.",
      "You moved your body today. That always counts.",
      "Workout done. Progress is built by days just like this one.",
      "Every rep, every step, every minute of effort adds up. You showed up.",
    ],
  },
  streak_3_day: {
    style: 'celebration',
    messages: [
      "Three days in a row. Momentum is building.",
      "3-day streak. You're creating a real pattern.",
      "Three consistent days. This is where habits are born.",
    ],
  },
  streak_7_day: {
    style: 'celebration',
    messages: [
      "One full week. You built something to be proud of.",
      "7 days straight. That's not luck — that's commitment.",
      "A week of consistency. This is exactly how progress happens.",
    ],
  },
  streak_14_day: {
    style: 'celebration',
    messages: [
      "Two weeks. Your future self is going to thank you.",
      "14 days. You've made this part of your life now.",
      "Two weeks of consistency is a genuine lifestyle shift. You're doing it.",
    ],
  },
  streak_30_day: {
    style: 'celebration',
    messages: [
      "30 days. A full month. You are not the same person who started.",
      "One month strong. That's not a phase — that's a transformation.",
      "Thirty days. Most people never get here. You did.",
    ],
  },
  weekly_review_completed: {
    style: 'supportive',
    messages: [
      "Weekly review done. Reflection is what separates the people who grow.",
      "You looked back at your week honestly. That's a powerful habit.",
      "Review complete. Now you know what to build on next week.",
    ],
  },
  returning_after_gap: {
    style: 'gentle',
    messages: [
      "You're back. A gap in the log isn't a failure — coming back is what matters.",
      "Welcome back. The best thing about progress is it waits for you.",
      "You stepped away and you stepped back. That takes courage. Let's keep going.",
      "A missed log is not a missed week. You're here now. That's what counts.",
      "Progress isn't ruined by a few quiet days. It's renewed by showing back up.",
    ],
  },
  weight_logged: {
    style: 'supportive',
    messages: [
      "Weight logged. Numbers are just data — not your worth.",
      "Tracking your weight is brave. The trend over time is what matters.",
      "Data logged. One number on one day doesn't define your progress.",
    ],
  },
  milestone_earned: {
    style: 'celebration',
    messages: [
      "Milestone unlocked. You earned this.",
      "A new achievement. You built this one rep, one log, one day at a time.",
      "Look what consistency does. You earned that.",
    ],
  },
  general_checkin: {
    style: 'supportive',
    messages: [
      "You're closer than you think.",
      "Progress is built by ordinary days done well.",
      "Consistency beats perfection. Every time.",
      "You are building momentum.",
      "Small wins stack. Keep going.",
      "You don't have to be perfect. You just have to show up.",
      "One good choice today leads to another tomorrow.",
      "The person you're becoming is showing up every day.",
    ],
  },
  morning_greeting: {
    style: 'motivating',
    messages: [
      "Good morning. Today is a fresh start.",
      "A new day. A new chance to take care of yourself.",
      "Morning. You've got this — one meal, one choice at a time.",
      "Start simple. Log your first meal and build from there.",
    ],
  },
  evening_checkin: {
    style: 'gentle',
    messages: [
      "How'd today go? Whatever it was, you're still here and that matters.",
      "End of day check-in. Every day you track is a data point for success.",
      "Evening. Reflect on one thing that went well today.",
      "What was your win today? Small or big — it counts.",
    ],
  },
}

// Static affirmations for UI decorations (no trigger needed)
export const AFFIRMATIONS = [
  "You showed up today. That matters.",
  "Progress is built by ordinary days done well.",
  "A missed log is not a failed week.",
  "You are building momentum.",
  "Consistency beats perfection.",
  "You're closer than you think.",
  "Every rep, every step, every bite logged — it adds up.",
  "You don't have to be extreme to make progress.",
  "The best plan is the one you actually follow.",
  "You are not your hardest day.",
  "Small actions compound into big change.",
  "Real progress is quiet and consistent.",
  "You're doing better than you think.",
  "One good choice opens the door to another.",
]

/**
 * Get a random encouragement message for a given trigger.
 * Returns a non-repeating random message from the relevant set.
 */
export function getEncouragementMessage(trigger: EncouragementTrigger): string {
  const set = ENCOURAGEMENT_LIBRARY[trigger]
  const messages = set.messages
  return messages[Math.floor(Math.random() * messages.length)]
}

/**
 * Get a random general affirmation for ambient display.
 */
export function getRandomAffirmation(): string {
  return AFFIRMATIONS[Math.floor(Math.random() * AFFIRMATIONS.length)]
}

/**
 * Determine which encouragement trigger applies based on current app state.
 * Called after any logging action to surface the right message.
 */
export function detectTrigger(context: {
  isFirstLogToday: boolean
  proteinGoalHit: boolean
  hydrationGoalHit: boolean
  workoutJustLogged: boolean
  currentStreak: number
  daysSinceLastLog: number
  weeklyReviewJustDone: boolean
  milestoneJustEarned: boolean
}): EncouragementTrigger | null {
  const {
    isFirstLogToday,
    proteinGoalHit,
    hydrationGoalHit,
    workoutJustLogged,
    currentStreak,
    daysSinceLastLog,
    weeklyReviewJustDone,
    milestoneJustEarned,
  } = context

  if (milestoneJustEarned) return 'milestone_earned'
  if (weeklyReviewJustDone) return 'weekly_review_completed'
  if (daysSinceLastLog >= 3) return 'returning_after_gap'
  if (workoutJustLogged) return 'workout_logged'
  if (proteinGoalHit) return 'protein_goal_hit'
  if (hydrationGoalHit) return 'hydration_goal_hit'
  if (currentStreak === 30) return 'streak_30_day'
  if (currentStreak === 14) return 'streak_14_day'
  if (currentStreak === 7) return 'streak_7_day'
  if (currentStreak === 3) return 'streak_3_day'
  if (isFirstLogToday) return 'first_meal_logged'

  return 'general_checkin'
}

// Supporter message templates (sent from supporter to primary user)
export const SUPPORTER_MESSAGES = [
  "I see you showing up every day. Keep going.",
  "So proud of your consistency.",
  "You're doing amazing. Just wanted you to know.",
  "I noticed your streak. That's impressive.",
  "Rooting for you every single day.",
  "You've got this. I believe in you.",
  "Your progress is inspiring. Keep it up.",
  "Today was a great day for you. I saw it.",
]

export function getRandomSupporterMessage(): string {
  return SUPPORTER_MESSAGES[Math.floor(Math.random() * SUPPORTER_MESSAGES.length)]
}

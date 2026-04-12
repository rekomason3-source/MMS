import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'
import { format, formatDistanceToNow, isToday, isYesterday } from 'date-fns'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// --- Number formatting ---
export function formatCalories(cal: number): string {
  return Math.round(cal).toLocaleString()
}

export function formatGrams(g: number): string {
  return `${Math.round(g)}g`
}

export function formatOz(oz: number): string {
  return `${Math.round(oz)} oz`
}

export function formatWeight(lbs: number): string {
  return `${lbs.toFixed(1)} lbs`
}

export function formatPercent(value: number, total: number): number {
  if (total === 0) return 0
  return Math.min(Math.round((value / total) * 100), 100)
}

// --- Date formatting ---
export function formatDate(date: string | Date): string {
  return format(new Date(date), 'MMM d, yyyy')
}

export function formatTime(date: string | Date): string {
  return format(new Date(date), 'h:mm a')
}

export function formatRelative(date: string | Date): string {
  const d = new Date(date)
  if (isToday(d)) return 'Today'
  if (isYesterday(d)) return 'Yesterday'
  return formatDistanceToNow(d, { addSuffix: true })
}

export function todayString(): string {
  return format(new Date(), 'yyyy-MM-dd')
}

export function getWeekDates(date: Date = new Date()): string[] {
  const day = date.getDay()
  const diff = date.getDate() - day + (day === 0 ? -6 : 1)
  const monday = new Date(date.setDate(diff))
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(monday)
    d.setDate(monday.getDate() + i)
    return format(d, 'yyyy-MM-dd')
  })
}

// --- Progress helpers ---
export function getProgressColor(percent: number): string {
  if (percent >= 100) return 'text-closer-sage'
  if (percent >= 75) return 'text-closer-teal'
  if (percent >= 50) return 'text-closer-gold'
  return 'text-muted-foreground'
}

export function getProgressBarColor(percent: number): string {
  if (percent >= 100) return 'bg-closer-sage'
  if (percent >= 75) return 'bg-closer-teal'
  if (percent >= 50) return 'bg-closer-gold'
  return 'bg-muted'
}

// --- Macro calorie calculation ---
export function macroToCalories(protein: number, carbs: number, fat: number): number {
  return protein * 4 + carbs * 4 + fat * 9
}

// --- Goal label helpers ---
export const PRIMARY_GOAL_LABELS: Record<string, string> = {
  lose_weight: 'Lose weight sustainably',
  build_muscle: 'Build strength & muscle',
  improve_nutrition: 'Improve nutrition',
  build_habits: 'Build healthy habits',
  stay_consistent: 'Stay consistent',
  postpartum_recovery: 'Postpartum wellness',
  general_wellness: 'General wellness',
}

export const WORKOUT_TYPE_LABELS: Record<string, string> = {
  walking: 'Walking',
  running: 'Running',
  strength: 'Strength Training',
  cardio: 'Cardio',
  yoga: 'Yoga',
  mobility: 'Mobility & Stretching',
  cycling: 'Cycling',
  swimming: 'Swimming',
  hiit: 'HIIT',
  custom: 'Custom Workout',
}

export const MEAL_TYPE_LABELS: Record<string, string> = {
  breakfast: 'Breakfast',
  lunch: 'Lunch',
  dinner: 'Dinner',
  snack: 'Snack',
  drink: 'Drink',
}

export const RELATIONSHIP_LABELS: Record<string, string> = {
  partner: 'Partner',
  spouse: 'Spouse',
  friend: 'Friend',
  family: 'Family Member',
  coach: 'Coach',
}

// --- Streak helpers ---
export function getStreakLabel(count: number): string {
  if (count === 0) return 'Start your streak'
  if (count === 1) return '1 day streak'
  return `${count} day streak`
}

export function getStreakEmoji(count: number): string {
  if (count >= 30) return '🔥'
  if (count >= 14) return '⚡'
  if (count >= 7) return '✨'
  if (count >= 3) return '🌱'
  return '💪'
}

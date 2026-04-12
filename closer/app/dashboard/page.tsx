'use client'

import Link from 'next/link'
import { format } from 'date-fns'
import { Bell, Settings, Plus, ChevronRight, Droplets, Moon, Heart } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { MacroRing } from '@/components/shared/macro-ring'
import { StatCard } from '@/components/shared/stat-card'
import { StreakBadge } from '@/components/shared/streak-badge'
import { EncouragementBanner } from '@/components/encouragement/encouragement-banner'
import {
  MOCK_PROFILE,
  MOCK_GOALS,
  MOCK_TODAY_MEALS,
  MOCK_TODAY_WORKOUTS,
  MOCK_STREAKS,
  computeTodayStats,
} from '@/lib/mock-data'
import { formatPercent, formatGrams, formatOz, MEAL_TYPE_LABELS } from '@/lib/utils'

export default function DashboardPage() {
  const stats = computeTodayStats(MOCK_GOALS)
  const goals = MOCK_GOALS
  const profile = MOCK_PROFILE

  const calPercent = formatPercent(stats.calories_consumed, goals.daily_calorie_target)
  const proteinPercent = formatPercent(stats.protein_consumed, goals.daily_protein_target)
  const waterPercent = formatPercent(stats.water_oz, goals.daily_water_target)
  const carbPercent = formatPercent(stats.carbs_consumed, goals.daily_carb_target)
  const fatPercent = formatPercent(stats.fat_consumed, goals.daily_fat_target)

  const logStreak = MOCK_STREAKS.find(s => s.streak_type === 'daily_log')
  const proteinStreak = MOCK_STREAKS.find(s => s.streak_type === 'protein_goal')

  const today = format(new Date(), 'EEEE, MMMM d')

  return (
    <div className="space-y-5 animate-fade-in">
      {/* Top bar */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs text-muted-foreground">{today}</p>
          <h1 className="text-xl font-semibold text-foreground">
            Good morning, {profile.display_name} 👋
          </h1>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/goals"><Settings className="w-5 h-5 text-muted-foreground" /></Link>
          </Button>
        </div>
      </div>

      {/* Encouragement */}
      <EncouragementBanner variant="card" />

      {/* Macro overview */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <div className="flex items-center gap-4">
          <MacroRing
            calories={stats.calories_consumed}
            calorieTarget={goals.daily_calorie_target}
            protein={stats.protein_consumed}
            proteinTarget={goals.daily_protein_target}
            size={110}
          />
          <div className="flex-1 space-y-2.5">
            {/* Protein — flagged as #1 metric */}
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="font-semibold text-closer-teal">Protein 💪</span>
                <span className="text-muted-foreground">{Math.round(stats.protein_consumed)}g / {goals.daily_protein_target}g</span>
              </div>
              <Progress value={proteinPercent} className="h-2" indicatorClassName="bg-closer-teal" />
            </div>
            {/* Carbs */}
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-muted-foreground">Carbs</span>
                <span className="text-muted-foreground">{Math.round(stats.carbs_consumed)}g / {goals.daily_carb_target}g</span>
              </div>
              <Progress value={carbPercent} className="h-1.5" indicatorClassName="bg-closer-gold" />
            </div>
            {/* Fat */}
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-muted-foreground">Fat</span>
                <span className="text-muted-foreground">{Math.round(stats.fat_consumed)}g / {goals.daily_fat_target}g</span>
              </div>
              <Progress value={fatPercent} className="h-1.5" indicatorClassName="bg-closer-blush" />
            </div>
          </div>
        </div>

        {/* Calorie bar */}
        <div className="mt-3 pt-3 border-t border-border">
          <div className="flex justify-between text-xs mb-1.5">
            <span className="font-medium text-foreground">Calories</span>
            <span className="text-muted-foreground">
              {Math.round(stats.calories_consumed)} / {goals.daily_calorie_target} kcal
            </span>
          </div>
          <Progress value={calPercent} className="h-2.5" indicatorClassName="bg-closer-sage" />
          <div className="flex justify-between text-[10px] text-muted-foreground mt-1">
            <span>{calPercent}% of daily goal</span>
            <span>{goals.daily_calorie_target - stats.calories_consumed > 0 ? `${goals.daily_calorie_target - stats.calories_consumed} remaining` : 'Goal reached'}</span>
          </div>
        </div>
      </div>

      {/* Quick stats row */}
      <div className="grid grid-cols-3 gap-3">
        <StatCard
          label="Water"
          value={`${stats.water_oz}`}
          target={`${goals.daily_water_target}oz`}
          percent={waterPercent}
          icon="💧"
          indicatorColor="bg-blue-400"
        />
        <StatCard
          label="Workouts"
          value={`${stats.workouts_completed}`}
          target={`${goals.weekly_workout_target}/wk`}
          icon="🏃"
          indicatorColor="bg-closer-teal"
        />
        <StatCard
          label="Sleep"
          value={stats.sleep_hours ? `${stats.sleep_hours}h` : '--'}
          target={`${goals.sleep_target}h`}
          percent={stats.sleep_hours ? formatPercent(stats.sleep_hours, goals.sleep_target) : 0}
          icon="😴"
          indicatorColor="bg-purple-400"
        />
      </div>

      {/* Streaks */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">Your streaks</h2>
        <div className="flex justify-around">
          <StreakBadge count={logStreak?.current_count ?? 0} label="Logging" size="md" />
          <StreakBadge count={proteinStreak?.current_count ?? 0} label="Protein" size="md" />
          <StreakBadge count={MOCK_STREAKS.find(s => s.streak_type === 'hydration_goal')?.current_count ?? 0} label="Hydration" size="md" />
          <StreakBadge count={MOCK_STREAKS.find(s => s.streak_type === 'workout')?.current_count ?? 0} label="Workouts" size="md" />
        </div>
      </div>

      {/* Today's meals */}
      <div className="bg-white rounded-2xl border border-border overflow-hidden">
        <div className="flex items-center justify-between p-4 pb-2">
          <h2 className="text-sm font-semibold text-foreground">Today's meals</h2>
          <Link href="/log/meal">
            <Button size="sm" variant="sage" className="h-7 text-xs">
              <Plus className="w-3.5 h-3.5 mr-1" /> Add
            </Button>
          </Link>
        </div>

        {MOCK_TODAY_MEALS.length === 0 ? (
          <div className="px-4 pb-4 text-center py-6">
            <p className="text-sm text-muted-foreground">No meals logged yet today.</p>
            <Link href="/log/meal">
              <Button variant="outline" size="sm" className="mt-3">Log your first meal</Button>
            </Link>
          </div>
        ) : (
          <div className="divide-y divide-border">
            {MOCK_TODAY_MEALS.map((meal) => (
              <div key={meal.id} className="flex items-center gap-3 px-4 py-3">
                <div className="w-9 h-9 rounded-xl bg-muted flex items-center justify-center text-base flex-shrink-0">
                  {meal.meal_type === 'breakfast' ? '🌅' : meal.meal_type === 'lunch' ? '☀️' : meal.meal_type === 'dinner' ? '🌙' : meal.meal_type === 'drink' ? '🥤' : '🍎'}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground truncate">{meal.title}</p>
                  <p className="text-xs text-muted-foreground">{MEAL_TYPE_LABELS[meal.meal_type]}</p>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="text-sm font-semibold text-foreground">{meal.calories} cal</p>
                  <p className="text-xs text-closer-teal">{meal.protein}g protein</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Today's workouts */}
      <div className="bg-white rounded-2xl border border-border overflow-hidden">
        <div className="flex items-center justify-between p-4 pb-2">
          <h2 className="text-sm font-semibold text-foreground">Movement today</h2>
          <Link href="/log/workout">
            <Button size="sm" variant="sage" className="h-7 text-xs">
              <Plus className="w-3.5 h-3.5 mr-1" /> Add
            </Button>
          </Link>
        </div>

        {MOCK_TODAY_WORKOUTS.length === 0 ? (
          <div className="px-4 pb-4 text-center py-6">
            <p className="text-sm text-muted-foreground">No workouts logged yet.</p>
          </div>
        ) : (
          <div className="divide-y divide-border">
            {MOCK_TODAY_WORKOUTS.map((w) => (
              <div key={w.id} className="flex items-center gap-3 px-4 py-3">
                <div className="w-9 h-9 rounded-xl bg-muted flex items-center justify-center text-base flex-shrink-0">
                  {w.workout_type === 'walking' ? '🚶' : w.workout_type === 'strength' ? '🏋️' : w.workout_type === 'yoga' ? '🧘' : '🏃'}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-foreground">{w.title}</p>
                  <p className="text-xs text-muted-foreground">{w.duration_minutes} min</p>
                </div>
                {w.calories_burned && (
                  <p className="text-sm text-muted-foreground">{w.calories_burned} cal</p>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Quick actions */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { href: '/log/water', icon: '💧', label: 'Log water' },
          { href: '/weekly-review', icon: '📊', label: 'Weekly review' },
          { href: '/milestones', icon: '🏆', label: 'Milestones' },
        ].map(({ href, icon, label }) => (
          <Link key={href} href={href}>
            <div className="bg-white border border-border rounded-2xl p-3 text-center hover:bg-muted/50 transition-colors cursor-pointer">
              <div className="text-xl mb-1">{icon}</div>
              <p className="text-xs text-muted-foreground font-medium">{label}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Mood check-in */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold text-foreground">How are you feeling?</h2>
          <Heart className="w-4 h-4 text-closer-blush" />
        </div>
        <div className="flex justify-around">
          {[
            { value: 1, emoji: '😔' },
            { value: 2, emoji: '😐' },
            { value: 3, emoji: '🙂' },
            { value: 4, emoji: '😊' },
            { value: 5, emoji: '🤩' },
          ].map(({ value, emoji }) => (
            <button
              key={value}
              className="w-11 h-11 rounded-2xl hover:bg-muted flex items-center justify-center text-xl transition-all hover:scale-110"
            >
              {emoji}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

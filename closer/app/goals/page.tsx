'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'
import { MOCK_GOALS, MOCK_PROFILE } from '@/lib/mock-data'
import { PRIMARY_GOALS, WORKOUT_DURATIONS } from '@/lib/constants'
import type { UserGoals, PrimaryGoal } from '@/types'
import { CheckCircle2, ChevronRight, Bell, Lock, LogOut } from 'lucide-react'

export default function GoalsPage() {
  const [goals, setGoals] = useState<UserGoals>(MOCK_GOALS)
  const [isSaved, setIsSaved] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const handleSave = async () => {
    setIsLoading(true)
    await new Promise(r => setTimeout(r, 600))
    setIsLoading(false)
    setIsSaved(true)
    setTimeout(() => setIsSaved(false), 2000)
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Goals & Settings</h1>
        <p className="text-sm text-muted-foreground">Adjust your targets anytime</p>
      </div>

      {/* Profile card */}
      <div className="bg-white rounded-2xl border border-border p-4 flex items-center gap-3">
        <div className="w-12 h-12 rounded-2xl bg-closer-sage/20 flex items-center justify-center text-xl flex-shrink-0">
          👤
        </div>
        <div className="flex-1">
          <p className="font-semibold text-foreground">{MOCK_PROFILE.full_name}</p>
          <p className="text-xs text-muted-foreground">{MOCK_PROFILE.plan === 'free' ? 'Free plan' : 'Plus plan'}</p>
        </div>
        <Badge variant={MOCK_PROFILE.plan === 'free' ? 'outline' : 'sage'} className="capitalize">
          {MOCK_PROFILE.plan}
        </Badge>
      </div>

      {/* Primary Goal */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">Primary goal</h2>
        <div className="space-y-2">
          {PRIMARY_GOALS.map(({ value, label, emoji }) => (
            <button
              key={value}
              onClick={() => setGoals({ ...goals, primary_goal: value as PrimaryGoal })}
              className={cn(
                'w-full flex items-center gap-3 p-3 rounded-xl border transition-all text-left',
                goals.primary_goal === value
                  ? 'border-primary bg-primary/5'
                  : 'border-border hover:bg-muted'
              )}
            >
              <span className="text-xl">{emoji}</span>
              <span className={cn('text-sm font-medium flex-1', goals.primary_goal === value ? 'text-primary' : 'text-foreground')}>
                {label}
              </span>
              {goals.primary_goal === value && <CheckCircle2 className="w-4 h-4 text-primary" />}
            </button>
          ))}
        </div>
      </div>

      {/* Nutrition targets */}
      <div className="bg-white rounded-2xl border border-border p-4 space-y-4">
        <h2 className="text-sm font-semibold text-foreground">Daily nutrition targets</h2>
        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1.5">
            <Label className="text-closer-teal">Protein (g) ★</Label>
            <Input
              type="number"
              value={goals.daily_protein_target}
              onChange={(e) => setGoals({ ...goals, daily_protein_target: Number(e.target.value) })}
              min={50} max={300}
              className="border-closer-teal/30"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Calories</Label>
            <Input
              type="number"
              value={goals.daily_calorie_target}
              onChange={(e) => setGoals({ ...goals, daily_calorie_target: Number(e.target.value) })}
              min={1000} max={5000}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Carbs (g)</Label>
            <Input
              type="number"
              value={goals.daily_carb_target}
              onChange={(e) => setGoals({ ...goals, daily_carb_target: Number(e.target.value) })}
              min={0} max={500}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Fat (g)</Label>
            <Input
              type="number"
              value={goals.daily_fat_target}
              onChange={(e) => setGoals({ ...goals, daily_fat_target: Number(e.target.value) })}
              min={0} max={200}
            />
          </div>
        </div>
      </div>

      {/* Hydration & fitness */}
      <div className="bg-white rounded-2xl border border-border p-4 space-y-4">
        <h2 className="text-sm font-semibold text-foreground">Hydration & fitness</h2>
        <div className="space-y-1.5">
          <Label>Daily water target (oz)</Label>
          <Input
            type="number"
            value={goals.daily_water_target}
            onChange={(e) => setGoals({ ...goals, daily_water_target: Number(e.target.value) })}
            min={32} max={200}
          />
        </div>
        <div className="space-y-1.5">
          <Label>Workouts per week</Label>
          <div className="flex gap-2">
            {[2, 3, 4, 5, 6].map((n) => (
              <button
                key={n}
                onClick={() => setGoals({ ...goals, weekly_workout_target: n })}
                className={cn(
                  'flex-1 py-2 rounded-xl border text-sm font-medium transition-all',
                  goals.weekly_workout_target === n ? 'bg-primary text-white border-primary' : 'border-border hover:bg-muted'
                )}
              >
                {n}
              </button>
            ))}
          </div>
        </div>
        <div className="space-y-1.5">
          <Label>Sleep target (hours)</Label>
          <Input
            type="number"
            value={goals.sleep_target}
            onChange={(e) => setGoals({ ...goals, sleep_target: Number(e.target.value) })}
            step={0.5} min={5} max={12}
          />
        </div>
      </div>

      {/* Weight goal */}
      <div className="bg-white rounded-2xl border border-border p-4 space-y-3">
        <h2 className="text-sm font-semibold text-foreground">Weight tracking</h2>
        {[
          { key: 'track_weight', label: 'Track body weight', emoji: '⚖️' },
          { key: 'track_measurements', label: 'Track measurements', emoji: '📏' },
          { key: 'track_photos', label: 'Progress photos', emoji: '📸' },
        ].map(({ key, label, emoji }) => (
          <button
            key={key}
            onClick={() => setGoals({ ...goals, [key]: !goals[key as keyof UserGoals] })}
            className={cn(
              'w-full flex items-center gap-3 p-3 rounded-xl border transition-all text-left',
              goals[key as keyof UserGoals] ? 'border-primary bg-primary/5' : 'border-border hover:bg-muted'
            )}
          >
            <span className="text-xl">{emoji}</span>
            <span className="text-sm font-medium flex-1 text-foreground">{label}</span>
            <div className={cn(
              'w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors',
              goals[key as keyof UserGoals] ? 'border-primary bg-primary' : 'border-border'
            )}>
              {goals[key as keyof UserGoals] && <CheckCircle2 className="w-3 h-3 text-white" />}
            </div>
          </button>
        ))}

        {goals.track_weight && (
          <div className="grid grid-cols-2 gap-3 pt-1">
            <div className="space-y-1.5">
              <Label>Starting weight (lbs)</Label>
              <Input
                type="number"
                value={goals.starting_weight || ''}
                onChange={(e) => setGoals({ ...goals, starting_weight: Number(e.target.value) })}
                placeholder="e.g. 168"
              />
            </div>
            <div className="space-y-1.5">
              <Label>Goal weight (lbs)</Label>
              <Input
                type="number"
                value={goals.target_weight || ''}
                onChange={(e) => setGoals({ ...goals, target_weight: Number(e.target.value) })}
                placeholder="e.g. 145"
              />
            </div>
          </div>
        )}
      </div>

      {/* Reminders */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <div className="flex items-center gap-2 mb-3">
          <Bell className="w-4 h-4 text-muted-foreground" />
          <h2 className="text-sm font-semibold text-foreground">Reminders</h2>
        </div>
        <button
          onClick={() => setGoals({ ...goals, reminder_enabled: !goals.reminder_enabled })}
          className={cn(
            'w-full flex items-center gap-3 p-3 rounded-xl border transition-all text-left',
            goals.reminder_enabled ? 'border-primary bg-primary/5' : 'border-border hover:bg-muted'
          )}
        >
          <span className="text-xl">{goals.reminder_enabled ? '🔔' : '🔕'}</span>
          <span className="text-sm font-medium flex-1 text-foreground">
            {goals.reminder_enabled ? 'Gentle reminders enabled' : 'Reminders off'}
          </span>
          <div className={cn(
            'w-10 h-6 rounded-full transition-colors relative',
            goals.reminder_enabled ? 'bg-primary' : 'bg-muted'
          )}>
            <div className={cn(
              'absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-transform',
              goals.reminder_enabled ? 'translate-x-4' : 'translate-x-0.5'
            )} />
          </div>
        </button>
      </div>

      {/* Upgrade banner */}
      {MOCK_PROFILE.plan === 'free' && (
        <div className="bg-gradient-to-r from-primary/10 to-closer-teal/10 border border-primary/20 rounded-2xl p-4">
          <div className="flex items-start gap-3">
            <Lock className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <p className="text-sm font-semibold text-foreground">Unlock Closer Plus</p>
              <p className="text-xs text-muted-foreground mt-0.5">Partner sharing, advanced charts, full history, and more.</p>
            </div>
            <Button size="sm" variant="sage">Upgrade</Button>
          </div>
        </div>
      )}

      <Button onClick={handleSave} className="w-full" disabled={isLoading}>
        {isLoading ? 'Saving...' : isSaved ? '✓ Saved!' : 'Save changes'}
      </Button>

      {/* Sign out */}
      <button className="w-full flex items-center justify-center gap-2 py-3 text-sm text-muted-foreground hover:text-foreground transition-colors">
        <LogOut className="w-4 h-4" />
        Sign out
      </button>
    </div>
  )
}

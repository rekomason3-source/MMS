'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { format, parseISO } from 'date-fns'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Progress } from '@/components/ui/progress'
import { EncouragementBanner } from '@/components/encouragement/encouragement-banner'
import { StreakBadge } from '@/components/shared/streak-badge'
import { cn, formatPercent } from '@/lib/utils'
import { MOCK_WEEKLY_SUMMARY, MOCK_GOALS, MOCK_STREAKS } from '@/lib/mock-data'
import { CheckCircle2, ChevronRight, TrendingDown, TrendingUp } from 'lucide-react'

const FOCUS_OPTIONS = [
  'Hit protein goal every day',
  'Work out 4+ times',
  'Drink 80oz water daily',
  'Sleep 7+ hours each night',
  'Log every meal',
  'Walk daily',
]

export default function WeeklyReviewPage() {
  const router = useRouter()
  const summary = MOCK_WEEKLY_SUMMARY
  const [customWin, setCustomWin] = useState('')
  const [selectedFocus, setSelectedFocus] = useState<string | null>(null)
  const [isComplete, setIsComplete] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  const proteinHitRate = formatPercent(5, 7) // 5/7 days
  const workoutRate = formatPercent(summary.workouts_completed, MOCK_GOALS.weekly_workout_target)
  const waterRate = formatPercent(summary.avg_water_oz, MOCK_GOALS.daily_water_target)

  const handleFinish = async () => {
    setIsLoading(true)
    await new Promise(r => setTimeout(r, 800))
    setIsLoading(false)
    setIsComplete(true)
  }

  if (isComplete) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[70vh] space-y-5 animate-fade-in text-center px-4">
        <div className="text-6xl animate-celebrate">🌟</div>
        <div>
          <h2 className="text-2xl font-bold text-foreground">Week reviewed!</h2>
          <p className="text-muted-foreground mt-2">Reflection is how winners are made.</p>
        </div>
        <EncouragementBanner message="Weekly review done. Reflection is what separates the people who grow." variant="card" className="w-full max-w-sm" />
        <StreakBadge count={MOCK_STREAKS.find(s => s.streak_type === 'daily_log')?.current_count ?? 0} label="Logging streak" size="lg" />
        <Button onClick={() => router.push('/dashboard')}>
          Back to dashboard <ChevronRight className="w-4 h-4 ml-1" />
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Weekly review</h1>
        <p className="text-sm text-muted-foreground">
          {format(parseISO(summary.week_start), 'MMM d')} – {format(parseISO(summary.week_end), 'MMM d, yyyy')}
        </p>
      </div>

      {/* Week at a glance */}
      <div className="bg-white rounded-2xl border border-border p-4 space-y-4">
        <h2 className="text-sm font-semibold text-foreground">This week at a glance</h2>

        {[
          { label: 'Avg Calories', value: `${summary.avg_calories} kcal`, target: `${MOCK_GOALS.daily_calorie_target}`, percent: formatPercent(summary.avg_calories, MOCK_GOALS.daily_calorie_target), color: 'bg-closer-sage' },
          { label: 'Avg Protein', value: `${summary.avg_protein}g`, target: `${MOCK_GOALS.daily_protein_target}g`, percent: formatPercent(summary.avg_protein, MOCK_GOALS.daily_protein_target), color: 'bg-closer-teal' },
          { label: 'Avg Water', value: `${summary.avg_water_oz}oz`, target: `${MOCK_GOALS.daily_water_target}oz`, percent: waterRate, color: 'bg-blue-400' },
          { label: 'Avg Sleep', value: `${summary.avg_sleep_hours}h`, target: `${MOCK_GOALS.sleep_target}h`, percent: formatPercent(summary.avg_sleep_hours, MOCK_GOALS.sleep_target), color: 'bg-purple-400' },
        ].map(({ label, value, target, percent, color }) => (
          <div key={label}>
            <div className="flex justify-between text-xs mb-1.5">
              <span className="text-muted-foreground">{label}</span>
              <span className="font-medium text-foreground">{value} <span className="text-muted-foreground font-normal">/ {target}</span></span>
            </div>
            <Progress value={percent} className="h-1.5" indicatorClassName={color} />
          </div>
        ))}
      </div>

      {/* Key metrics */}
      <div className="grid grid-cols-2 gap-3">
        <div className="bg-white rounded-2xl border border-border p-4 text-center">
          <div className="text-2xl font-bold text-foreground">{summary.workouts_completed}</div>
          <div className="text-xs text-muted-foreground mt-0.5">workouts</div>
          <Progress value={workoutRate} className="h-1 mt-2" indicatorClassName="bg-closer-teal" />
        </div>
        <div className="bg-white rounded-2xl border border-border p-4 text-center">
          <div className={cn('text-2xl font-bold', (summary.weight_change_lbs ?? 0) < 0 ? 'text-closer-sage' : 'text-foreground')}>
            {summary.weight_change_lbs !== undefined ? (
              <span className="flex items-center justify-center gap-1">
                {summary.weight_change_lbs < 0 ? <TrendingDown className="w-4 h-4" /> : <TrendingUp className="w-4 h-4" />}
                {summary.weight_change_lbs > 0 ? '+' : ''}{summary.weight_change_lbs.toFixed(1)}
              </span>
            ) : '--'}
          </div>
          <div className="text-xs text-muted-foreground mt-0.5">lbs this week</div>
        </div>
        <div className="bg-white rounded-2xl border border-border p-4 text-center">
          <div className="text-2xl font-bold text-closer-gold">{proteinHitRate}%</div>
          <div className="text-xs text-muted-foreground mt-0.5">protein goal hit rate</div>
        </div>
        <div className="bg-white rounded-2xl border border-border p-4 text-center">
          <div className="text-2xl font-bold text-foreground">{summary.best_streak}</div>
          <div className="text-xs text-muted-foreground mt-0.5">day best streak</div>
        </div>
      </div>

      {/* Wins */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">Wins this week 🎉</h2>
        <div className="space-y-2">
          {summary.weekly_wins.map((win) => (
            <div key={win} className="flex items-start gap-2">
              <CheckCircle2 className="w-4 h-4 text-closer-sage mt-0.5 flex-shrink-0" />
              <p className="text-sm text-foreground">{win}</p>
            </div>
          ))}
        </div>
        <div className="mt-3 pt-3 border-t border-border">
          <p className="text-xs text-muted-foreground mb-2">Add your own win</p>
          <Textarea
            placeholder="What else went well this week?"
            value={customWin}
            onChange={(e) => setCustomWin(e.target.value)}
            rows={2}
          />
        </div>
      </div>

      {/* Next week focus */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-1">Focus for next week</h2>
        <p className="text-xs text-muted-foreground mb-3">Choose one thing to prioritize.</p>
        <div className="grid grid-cols-2 gap-2">
          {FOCUS_OPTIONS.map((opt) => (
            <button
              key={opt}
              onClick={() => setSelectedFocus(opt)}
              className={cn(
                'py-2.5 px-3 rounded-xl border text-xs font-medium text-left transition-all',
                selectedFocus === opt
                  ? 'bg-primary/10 border-primary text-primary'
                  : 'border-border hover:bg-muted text-foreground'
              )}
            >
              {opt}
            </button>
          ))}
        </div>
      </div>

      <EncouragementBanner variant="card" />

      <Button onClick={handleFinish} className="w-full" disabled={isLoading}>
        {isLoading ? 'Saving...' : 'Complete weekly review ✓'}
      </Button>
    </div>
  )
}

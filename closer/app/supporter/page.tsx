'use client'

import { useState } from 'react'
import Link from 'next/link'
import { format, parseISO } from 'date-fns'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { StreakBadge } from '@/components/shared/streak-badge'
import { cn, formatPercent } from '@/lib/utils'
import {
  MOCK_PROFILE,
  MOCK_GOALS,
  MOCK_TODAY_MEALS,
  MOCK_TODAY_WORKOUTS,
  MOCK_STREAKS,
  MOCK_WEIGHT_DATA,
  computeTodayStats,
} from '@/lib/mock-data'
import { SUPPORTER_MESSAGES, getRandomSupporterMessage } from '@/lib/encouragement'
import { UserPlus, Heart, Star, TrendingDown, Send, Lock } from 'lucide-react'

// Mock: viewing as a supporter for Sarah
const SUPPORTER = { name: 'Mike', relationship: 'Spouse' }

export default function SupporterPage() {
  const stats = computeTodayStats(MOCK_GOALS)
  const goals = MOCK_GOALS
  const [sentMessage, setSentMessage] = useState<string | null>(null)
  const [customMessage, setCustomMessage] = useState('')

  const calPercent = formatPercent(stats.calories_consumed, goals.daily_calorie_target)
  const proteinPercent = formatPercent(stats.protein_consumed, goals.daily_protein_target)
  const waterPercent = formatPercent(stats.water_oz, goals.daily_water_target)

  const currentWeight = MOCK_WEIGHT_DATA[MOCK_WEIGHT_DATA.length - 1].weight
  const startWeight = MOCK_WEIGHT_DATA[0].weight
  const weightChange = currentWeight - startWeight

  const sendEncouragement = (msg: string) => {
    setSentMessage(msg)
    setTimeout(() => setSentMessage(null), 3000)
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Support</h1>
          <p className="text-sm text-muted-foreground">Be the reason someone keeps going</p>
        </div>
        <Link href="/invite">
          <Button size="sm" variant="sage">
            <UserPlus className="w-4 h-4 mr-1" /> Invite
          </Button>
        </Link>
      </div>

      {/* Supported person card */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 rounded-2xl bg-closer-sage/20 flex items-center justify-center text-xl">
            👤
          </div>
          <div className="flex-1">
            <p className="font-semibold text-foreground">{MOCK_PROFILE.full_name}</p>
            <div className="flex items-center gap-2 mt-0.5">
              <Badge variant="sage" className="text-[10px]">{SUPPORTER.relationship}</Badge>
              <span className="text-xs text-muted-foreground">Active today</span>
            </div>
          </div>
          <StreakBadge count={MOCK_STREAKS[0].current_count} size="sm" />
        </div>

        {/* Today's quick stats */}
        <div className="space-y-2.5">
          <div>
            <div className="flex justify-between text-xs mb-1">
              <span className="text-muted-foreground">Protein 💪</span>
              <span className="font-medium text-closer-teal">{Math.round(stats.protein_consumed)}g / {goals.daily_protein_target}g</span>
            </div>
            <Progress value={proteinPercent} className="h-1.5" indicatorClassName="bg-closer-teal" />
          </div>
          <div>
            <div className="flex justify-between text-xs mb-1">
              <span className="text-muted-foreground">Calories</span>
              <span className="font-medium">{Math.round(stats.calories_consumed)} / {goals.daily_calorie_target}</span>
            </div>
            <Progress value={calPercent} className="h-1.5" indicatorClassName="bg-closer-sage" />
          </div>
          <div>
            <div className="flex justify-between text-xs mb-1">
              <span className="text-muted-foreground">Water 💧</span>
              <span className="font-medium">{stats.water_oz}oz / {goals.daily_water_target}oz</span>
            </div>
            <Progress value={waterPercent} className="h-1.5" indicatorClassName="bg-blue-400" />
          </div>
        </div>

        {/* Weight progress */}
        <div className={cn('mt-3 pt-3 border-t border-border flex items-center gap-2',)}>
          <TrendingDown className="w-4 h-4 text-closer-sage" />
          <span className="text-sm text-foreground">
            <strong className="text-closer-sage">{Math.abs(weightChange).toFixed(1)} lbs down</strong> from starting weight
          </span>
        </div>
      </div>

      {/* Send encouragement */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <div className="flex items-center gap-2 mb-3">
          <Heart className="w-4 h-4 text-closer-blush" />
          <h2 className="text-sm font-semibold text-foreground">Send encouragement</h2>
        </div>

        {sentMessage && (
          <div className="bg-closer-sage/10 border border-closer-sage/20 rounded-xl p-3 mb-3 flex items-center gap-2 animate-fade-in">
            <Star className="w-4 h-4 text-closer-sage flex-shrink-0" />
            <p className="text-xs text-closer-sage">Sent! "{sentMessage}"</p>
          </div>
        )}

        <div className="space-y-2">
          {SUPPORTER_MESSAGES.slice(0, 4).map((msg) => (
            <button
              key={msg}
              onClick={() => sendEncouragement(msg)}
              className="w-full flex items-center justify-between p-3 rounded-xl border border-border hover:bg-muted/50 transition-all text-left group"
            >
              <p className="text-sm text-foreground">{msg}</p>
              <Send className="w-3.5 h-3.5 text-muted-foreground group-hover:text-primary transition-colors flex-shrink-0 ml-2" />
            </button>
          ))}
        </div>

        {/* Custom message */}
        <div className="mt-3 pt-3 border-t border-border">
          <div className="flex gap-2">
            <input
              type="text"
              placeholder="Write your own message..."
              value={customMessage}
              onChange={(e) => setCustomMessage(e.target.value)}
              className="flex-1 h-10 px-3 rounded-xl border border-input bg-background text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            />
            <Button
              size="icon"
              onClick={() => { if (customMessage) { sendEncouragement(customMessage); setCustomMessage('') } }}
              disabled={!customMessage}
            >
              <Send className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>

      {/* Today's meals visible */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">What they ate today</h2>
        <div className="space-y-2">
          {MOCK_TODAY_MEALS.map((meal) => (
            <div key={meal.id} className="flex items-center justify-between py-1">
              <div>
                <p className="text-sm text-foreground">{meal.title}</p>
                <p className="text-xs text-muted-foreground">{meal.meal_type}</p>
              </div>
              <div className="text-right">
                <p className="text-sm font-medium">{meal.calories} cal</p>
                <p className="text-xs text-closer-teal">{meal.protein}g protein</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Upgrade prompt for more features */}
      <div className="bg-muted rounded-2xl border border-border p-4">
        <div className="flex items-start gap-3">
          <Lock className="w-4 h-4 text-muted-foreground mt-0.5 flex-shrink-0" />
          <div>
            <p className="text-sm font-semibold text-foreground">Closer Plus</p>
            <p className="text-xs text-muted-foreground mt-0.5">
              Unlock progress charts, full history, smart insights, and up to 2 supporters.
            </p>
            <Button size="sm" variant="outline" className="mt-2">Upgrade — $9.99/mo</Button>
          </div>
        </div>
      </div>
    </div>
  )
}

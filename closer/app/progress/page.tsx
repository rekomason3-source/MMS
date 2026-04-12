'use client'

import { useState } from 'react'
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import { format, parseISO } from 'date-fns'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { StreakBadge } from '@/components/shared/streak-badge'
import { EncouragementBanner } from '@/components/encouragement/encouragement-banner'
import { cn } from '@/lib/utils'
import {
  MOCK_WEIGHT_DATA,
  MOCK_MACRO_DATA,
  MOCK_GOALS,
  MOCK_STREAKS,
  MOCK_BADGES,
} from '@/lib/mock-data'
import { TrendingDown, Camera, Plus } from 'lucide-react'

type Tab = 'weight' | 'nutrition' | 'streaks'

const RANGE_OPTIONS = [
  { label: '7D', days: 7 },
  { label: '14D', days: 14 },
  { label: '30D', days: 30 },
]

// Non-scale victories for display
const NSV = [
  { emoji: '💪', text: 'Clothes fitting better' },
  { emoji: '⚡', text: 'More energy in the mornings' },
  { emoji: '😴', text: 'Sleeping better' },
  { emoji: '🧠', text: 'Clearer mental focus' },
]

export default function ProgressPage() {
  const [activeTab, setActiveTab] = useState<Tab>('weight')
  const [range, setRange] = useState(14)

  const weightData = MOCK_WEIGHT_DATA.slice(-range).map(d => ({
    ...d,
    date: format(parseISO(d.date), 'M/d'),
  }))

  const macroData = MOCK_MACRO_DATA.slice(-range).map(d => ({
    ...d,
    date: format(parseISO(d.date), 'M/d'),
  }))

  const startWeight = MOCK_WEIGHT_DATA[0].weight
  const currentWeight = MOCK_WEIGHT_DATA[MOCK_WEIGHT_DATA.length - 1].weight
  const totalChange = currentWeight - startWeight
  const targetWeight = MOCK_GOALS.target_weight || 0
  const remaining = currentWeight - targetWeight

  return (
    <div className="space-y-5 animate-fade-in">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Progress</h1>
        <p className="text-sm text-muted-foreground">The trend is what matters</p>
      </div>

      {/* Weight summary cards */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-2xl border border-border p-3 text-center">
          <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">Starting</p>
          <p className="text-lg font-bold text-foreground">{startWeight.toFixed(1)}</p>
          <p className="text-[10px] text-muted-foreground">lbs</p>
        </div>
        <div className="bg-white rounded-2xl border border-border p-3 text-center">
          <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">Current</p>
          <p className="text-lg font-bold text-closer-sage">{currentWeight.toFixed(1)}</p>
          <p className="text-[10px] text-muted-foreground">lbs</p>
        </div>
        <div className="bg-white rounded-2xl border border-border p-3 text-center">
          <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">Change</p>
          <div className="flex items-center justify-center gap-0.5">
            {totalChange < 0 && <TrendingDown className="w-3.5 h-3.5 text-closer-sage" />}
            <p className={cn('text-lg font-bold', totalChange < 0 ? 'text-closer-sage' : 'text-foreground')}>
              {totalChange > 0 ? '+' : ''}{totalChange.toFixed(1)}
            </p>
          </div>
          <p className="text-[10px] text-muted-foreground">lbs</p>
        </div>
      </div>

      {remaining > 0 && (
        <div className="bg-closer-sage/10 border border-closer-sage/20 rounded-2xl p-3 flex items-center gap-3">
          <div className="text-2xl">🎯</div>
          <div>
            <p className="text-sm font-semibold text-closer-sage">{remaining.toFixed(1)} lbs to goal</p>
            <p className="text-xs text-muted-foreground">You're making real progress. Keep going.</p>
          </div>
        </div>
      )}

      {/* Tab selector */}
      <div className="flex gap-1 bg-muted rounded-xl p-1">
        {(['weight', 'nutrition', 'streaks'] as Tab[]).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              'flex-1 py-2 rounded-lg text-xs font-semibold capitalize transition-all',
              activeTab === tab ? 'bg-white shadow-sm text-foreground' : 'text-muted-foreground'
            )}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Range selector */}
      {activeTab !== 'streaks' && (
        <div className="flex gap-2">
          {RANGE_OPTIONS.map(({ label, days }) => (
            <button
              key={days}
              onClick={() => setRange(days)}
              className={cn(
                'px-3 py-1.5 rounded-lg border text-xs font-medium transition-all',
                range === days ? 'bg-primary text-white border-primary' : 'bg-white border-border text-muted-foreground'
              )}
            >
              {label}
            </button>
          ))}
        </div>
      )}

      {/* Weight chart */}
      {activeTab === 'weight' && (
        <div className="space-y-4">
          <div className="bg-white rounded-2xl border border-border p-4">
            <h2 className="text-sm font-semibold text-foreground mb-4">Weight trend</h2>
            <ResponsiveContainer width="100%" height={180}>
              <LineChart data={weightData} margin={{ top: 5, right: 5, bottom: 5, left: -20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} />
                <YAxis
                  tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }}
                  domain={['dataMin - 2', 'dataMax + 2']}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: '12px',
                    border: '1px solid hsl(var(--border))',
                    fontSize: '12px',
                  }}
                  formatter={(v: number) => [`${v.toFixed(1)} lbs`, 'Weight']}
                />
                <Line
                  type="monotone"
                  dataKey="weight"
                  stroke="#6B8F71"
                  strokeWidth={2.5}
                  dot={false}
                  activeDot={{ r: 5, fill: '#6B8F71' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Non-scale victories */}
          <div className="bg-white rounded-2xl border border-border p-4">
            <h2 className="text-sm font-semibold text-foreground mb-3">Non-scale victories</h2>
            <p className="text-xs text-muted-foreground mb-3">Progress shows up in many ways beyond the scale.</p>
            <div className="grid grid-cols-2 gap-2">
              {NSV.map(({ emoji, text }) => (
                <div key={text} className="flex items-center gap-2 p-2.5 bg-muted/50 rounded-xl">
                  <span className="text-base">{emoji}</span>
                  <span className="text-xs text-foreground">{text}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Progress photos placeholder */}
          <div className="bg-white rounded-2xl border border-border p-4">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-sm font-semibold text-foreground">Progress photos</h2>
              <Badge variant="sage">Free</Badge>
            </div>
            <div className="border-2 border-dashed border-border rounded-xl p-6 text-center">
              <Camera className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">Add your first progress photo</p>
              <Button size="sm" variant="outline" className="mt-3">
                <Plus className="w-3.5 h-3.5 mr-1" /> Add photo
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Nutrition chart */}
      {activeTab === 'nutrition' && (
        <div className="space-y-4">
          <div className="bg-white rounded-2xl border border-border p-4">
            <h2 className="text-sm font-semibold text-foreground mb-1">Protein trend</h2>
            <p className="text-xs text-muted-foreground mb-4">Daily target: {MOCK_GOALS.daily_protein_target}g</p>
            <ResponsiveContainer width="100%" height={160}>
              <BarChart data={macroData} margin={{ top: 5, right: 5, bottom: 5, left: -20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} />
                <YAxis tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} />
                <Tooltip
                  contentStyle={{ borderRadius: '12px', border: '1px solid hsl(var(--border))', fontSize: '12px' }}
                  formatter={(v: number) => [`${v}g`, 'Protein']}
                />
                {/* Target line using custom reference via a calculated Recharts trick */}
                <Bar dataKey="protein" fill="#4A9B8E" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          <div className="bg-white rounded-2xl border border-border p-4">
            <h2 className="text-sm font-semibold text-foreground mb-1">Calorie trend</h2>
            <p className="text-xs text-muted-foreground mb-4">Daily target: {MOCK_GOALS.daily_calorie_target} kcal</p>
            <ResponsiveContainer width="100%" height={160}>
              <BarChart data={macroData} margin={{ top: 5, right: 5, bottom: 5, left: -20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} />
                <YAxis tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} />
                <Tooltip
                  contentStyle={{ borderRadius: '12px', border: '1px solid hsl(var(--border))', fontSize: '12px' }}
                  formatter={(v: number) => [`${v} kcal`, 'Calories']}
                />
                <Bar dataKey="calories" fill="#6B8F71" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Streaks */}
      {activeTab === 'streaks' && (
        <div className="space-y-4">
          <div className="bg-white rounded-2xl border border-border p-4">
            <h2 className="text-sm font-semibold text-foreground mb-4">Current streaks</h2>
            <div className="space-y-4">
              {[
                { streak: MOCK_STREAKS.find(s => s.streak_type === 'daily_log'), label: 'Daily logging', emoji: '📝' },
                { streak: MOCK_STREAKS.find(s => s.streak_type === 'protein_goal'), label: 'Protein goal', emoji: '💪' },
                { streak: MOCK_STREAKS.find(s => s.streak_type === 'hydration_goal'), label: 'Hydration goal', emoji: '💧' },
                { streak: MOCK_STREAKS.find(s => s.streak_type === 'workout'), label: 'Workout streak', emoji: '🏃' },
              ].map(({ streak, label, emoji }) => (
                <div key={label} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-lg">{emoji}</span>
                    <div>
                      <p className="text-sm font-medium text-foreground">{label}</p>
                      <p className="text-xs text-muted-foreground">Best: {streak?.longest_count ?? 0} days</p>
                    </div>
                  </div>
                  <StreakBadge count={streak?.current_count ?? 0} />
                </div>
              ))}
            </div>
          </div>

          <EncouragementBanner variant="card" />

          {/* Recent badges */}
          <div className="bg-white rounded-2xl border border-border p-4">
            <h2 className="text-sm font-semibold text-foreground mb-3">Recent badges</h2>
            <div className="flex flex-wrap gap-2">
              {MOCK_BADGES.slice(0, 4).map((ub) => (
                <div
                  key={ub.id}
                  className="flex items-center gap-1.5 bg-muted rounded-xl px-3 py-2"
                >
                  <span className="text-base">{ub.badge.icon}</span>
                  <span className="text-xs font-medium text-foreground">{ub.badge.title}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

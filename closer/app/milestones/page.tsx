'use client'

import { useState } from 'react'
import { format, parseISO } from 'date-fns'
import { Badge } from '@/components/ui/badge'
import { EncouragementBanner } from '@/components/encouragement/encouragement-banner'
import { cn } from '@/lib/utils'
import { BADGE_DEFINITIONS } from '@/lib/constants'
import { MOCK_BADGES } from '@/lib/mock-data'
import { Lock } from 'lucide-react'

type FilterCategory = 'all' | 'logging' | 'nutrition' | 'fitness' | 'consistency' | 'support'

const CATEGORIES: { value: FilterCategory; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'logging', label: 'Logging' },
  { value: 'nutrition', label: 'Nutrition' },
  { value: 'fitness', label: 'Fitness' },
  { value: 'consistency', label: 'Consistency' },
  { value: 'support', label: 'Support' },
]

export default function MilestonesPage() {
  const [filter, setFilter] = useState<FilterCategory>('all')

  const earnedBadgeKeys = new Set(MOCK_BADGES.map(ub => ub.badge_id))

  const filtered = BADGE_DEFINITIONS.filter(b =>
    filter === 'all' || b.category === filter
  )

  return (
    <div className="space-y-5 animate-fade-in">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Milestones & Badges</h1>
        <p className="text-sm text-muted-foreground">
          {MOCK_BADGES.length} earned · {BADGE_DEFINITIONS.length - MOCK_BADGES.length} to unlock
        </p>
      </div>

      {/* Earned count */}
      <div className="bg-gradient-to-r from-closer-sage/15 to-closer-teal/15 rounded-2xl p-4 border border-closer-sage/20">
        <div className="flex items-center gap-3">
          <div className="text-4xl">🏆</div>
          <div>
            <p className="text-lg font-bold text-foreground">{MOCK_BADGES.length} badges earned</p>
            <p className="text-sm text-muted-foreground">You're building something real. Keep going.</p>
          </div>
        </div>
      </div>

      {/* Category filter */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {CATEGORIES.map(({ value, label }) => (
          <button
            key={value}
            onClick={() => setFilter(value)}
            className={cn(
              'flex-shrink-0 px-3 py-1.5 rounded-xl border text-xs font-medium transition-all',
              filter === value ? 'bg-primary text-white border-primary' : 'bg-white border-border text-muted-foreground hover:bg-muted'
            )}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Earned badges */}
      {MOCK_BADGES.filter(ub => filter === 'all' || ub.badge.category === filter).length > 0 && (
        <div>
          <h2 className="text-sm font-semibold text-foreground mb-3">Earned</h2>
          <div className="grid grid-cols-2 gap-3">
            {MOCK_BADGES
              .filter(ub => filter === 'all' || ub.badge.category === filter)
              .map((ub) => (
                <div
                  key={ub.id}
                  className="bg-white rounded-2xl border border-border p-4 text-center animate-fade-in"
                >
                  <div className="text-3xl mb-2">{ub.badge.icon}</div>
                  <p className="text-sm font-semibold text-foreground">{ub.badge.title}</p>
                  <p className="text-xs text-muted-foreground mt-1 leading-relaxed">{ub.badge.description}</p>
                  <Badge variant="sage" className="mt-2 text-[10px]">
                    {format(parseISO(ub.earned_at), 'MMM d')}
                  </Badge>
                </div>
              ))
            }
          </div>
        </div>
      )}

      {/* Locked badges */}
      <div>
        <h2 className="text-sm font-semibold text-foreground mb-3">Upcoming</h2>
        <div className="grid grid-cols-2 gap-3">
          {filtered
            .filter(b => !earnedBadgeKeys.has(b.key))
            .map((badge) => (
              <div
                key={badge.key}
                className="bg-white rounded-2xl border border-border p-4 text-center opacity-60"
              >
                <div className="relative inline-block mb-2">
                  <span className="text-3xl grayscale">{badge.icon}</span>
                  <Lock className="w-3.5 h-3.5 text-muted-foreground absolute -bottom-0.5 -right-1" />
                </div>
                <p className="text-sm font-semibold text-foreground">{badge.title}</p>
                <p className="text-xs text-muted-foreground mt-1 leading-relaxed">{badge.description}</p>
                <Badge variant="outline" className="mt-2 text-[10px]">Locked</Badge>
              </div>
            ))
          }
        </div>
      </div>

      <EncouragementBanner variant="card" />
    </div>
  )
}

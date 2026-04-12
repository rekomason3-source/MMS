'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Progress } from '@/components/ui/progress'
import { EncouragementBanner } from '@/components/encouragement/encouragement-banner'
import { cn, formatPercent } from '@/lib/utils'
import { WATER_QUICK_ADD } from '@/lib/constants'
import { MOCK_TODAY_WATER, MOCK_GOALS } from '@/lib/mock-data'
import { ArrowLeft, Plus } from 'lucide-react'

export default function AddWaterPage() {
  const router = useRouter()
  const currentOz = MOCK_TODAY_WATER.reduce((s, w) => s + w.amount_oz, 0)
  const targetOz = MOCK_GOALS.daily_water_target
  const [added, setAdded] = useState(0)
  const [customOz, setCustomOz] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [showSuccess, setShowSuccess] = useState(false)

  const total = currentOz + added
  const percent = formatPercent(total, targetOz)
  const goalHit = total >= targetOz

  const addWater = (oz: number) => setAdded(a => a + oz)

  const handleSave = async () => {
    if (added === 0) return
    setIsLoading(true)
    await new Promise(r => setTimeout(r, 400))
    setIsLoading(false)
    if (goalHit) {
      setShowSuccess(true)
      setTimeout(() => router.push('/dashboard'), 1800)
    } else {
      router.push('/dashboard')
    }
  }

  if (showSuccess) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4 animate-fade-in">
        <div className="text-5xl animate-celebrate">💧</div>
        <h2 className="text-xl font-bold text-foreground">Hydration goal hit!</h2>
        <EncouragementBanner message="You're well hydrated today. That matters more than most people realize." variant="card" className="w-full max-w-sm" />
      </div>
    )
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="flex items-center gap-3">
        <Link href="/dashboard">
          <Button variant="ghost" size="icon-sm"><ArrowLeft className="w-4 h-4" /></Button>
        </Link>
        <div>
          <h1 className="text-xl font-semibold text-foreground">Log water</h1>
          <p className="text-xs text-muted-foreground">Small sips. Big difference.</p>
        </div>
      </div>

      {/* Water progress visual */}
      <div className="bg-white rounded-2xl border border-border p-6 text-center">
        <div className="relative mx-auto w-32 h-32 mb-4">
          {/* Water bottle visual */}
          <svg viewBox="0 0 80 120" className="w-full h-full">
            <rect x="20" y="10" width="40" height="100" rx="8" fill="hsl(var(--muted))" />
            <rect
              x="20"
              y={10 + (100 - Math.min(percent, 100))}
              width="40"
              height={Math.min(percent, 100)}
              rx="8"
              fill="#60a5fa"
              className="transition-all duration-500"
            />
            <rect x="28" y="4" width="24" height="10" rx="3" fill="hsl(var(--muted))" />
          </svg>
          {goalHit && (
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-2xl">✅</span>
            </div>
          )}
        </div>

        <div className="text-3xl font-bold text-foreground">{total}<span className="text-lg font-normal text-muted-foreground">oz</span></div>
        <div className="text-sm text-muted-foreground mt-1">of {targetOz}oz goal · {percent}%</div>

        <Progress value={percent} className="h-2 mt-3" indicatorClassName="bg-blue-400" />

        {added > 0 && (
          <p className="text-xs text-muted-foreground mt-2">+{added}oz added this session</p>
        )}
      </div>

      {/* Quick add */}
      <div>
        <h2 className="text-sm font-semibold text-foreground mb-3">Quick add</h2>
        <div className="grid grid-cols-3 gap-2">
          {WATER_QUICK_ADD.map((oz) => (
            <button
              key={oz}
              onClick={() => addWater(oz)}
              className="bg-white border border-border rounded-xl py-3 text-sm font-semibold text-foreground hover:bg-blue-50 hover:border-blue-300 transition-all"
            >
              +{oz} oz
            </button>
          ))}
        </div>
      </div>

      {/* Custom amount */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">Custom amount</h2>
        <div className="flex gap-2">
          <Input
            type="number"
            placeholder="oz"
            value={customOz}
            onChange={(e) => setCustomOz(e.target.value)}
            min={1}
            max={200}
          />
          <Button
            onClick={() => {
              if (customOz) {
                addWater(Number(customOz))
                setCustomOz('')
              }
            }}
            variant="outline"
            disabled={!customOz}
          >
            <Plus className="w-4 h-4" />
          </Button>
        </div>
      </div>

      <Button
        onClick={handleSave}
        className="w-full"
        disabled={added === 0 || isLoading}
      >
        {isLoading ? 'Saving...' : `Save +${added}oz`}
      </Button>
    </div>
  )
}

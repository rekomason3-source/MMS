'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { EncouragementBanner } from '@/components/encouragement/encouragement-banner'
import { cn } from '@/lib/utils'
import { WORKOUT_TYPES, WORKOUT_DURATIONS } from '@/lib/constants'
import { ArrowLeft } from 'lucide-react'
import type { WorkoutType } from '@/types'

interface WorkoutForm {
  workout_type: WorkoutType
  title: string
  duration_minutes: number
  calories_burned: string
  notes: string
}

export default function AddWorkoutPage() {
  const router = useRouter()
  const [form, setForm] = useState<WorkoutForm>({
    workout_type: 'walking',
    title: '',
    duration_minutes: 30,
    calories_burned: '',
    notes: '',
  })
  const [isLoading, setIsLoading] = useState(false)
  const [showSuccess, setShowSuccess] = useState(false)

  const selectedType = WORKOUT_TYPES.find(t => t.value === form.workout_type)

  const handleTypeSelect = (type: typeof WORKOUT_TYPES[0]) => {
    setForm({
      ...form,
      workout_type: type.value as WorkoutType,
      title: type.label,
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    await new Promise(r => setTimeout(r, 600))
    setIsLoading(false)
    setShowSuccess(true)
    setTimeout(() => router.push('/dashboard'), 1500)
  }

  if (showSuccess) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4 animate-fade-in">
        <div className="text-5xl animate-celebrate">💪</div>
        <h2 className="text-xl font-bold text-foreground">Workout logged!</h2>
        <EncouragementBanner message="Movement logged. You're one step closer." variant="card" className="w-full max-w-sm" />
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
          <h1 className="text-xl font-semibold text-foreground">Log workout</h1>
          <p className="text-xs text-muted-foreground">Any movement counts — celebrate it</p>
        </div>
      </div>

      {/* Workout type grid */}
      <div>
        <h2 className="text-sm font-semibold text-foreground mb-3">Type of workout</h2>
        <div className="grid grid-cols-4 gap-2">
          {WORKOUT_TYPES.map((type) => (
            <button
              key={type.value}
              onClick={() => handleTypeSelect(type)}
              className={cn(
                'flex flex-col items-center gap-1 py-3 px-2 rounded-xl border text-center transition-all',
                form.workout_type === type.value
                  ? 'bg-primary/10 border-primary text-primary'
                  : 'bg-white border-border text-muted-foreground hover:bg-muted'
              )}
            >
              <span className="text-xl">{type.emoji}</span>
              <span className="text-[10px] font-medium leading-tight">{type.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Duration quick-select */}
      <div>
        <h2 className="text-sm font-semibold text-foreground mb-3">Duration</h2>
        <div className="flex gap-2 flex-wrap">
          {WORKOUT_DURATIONS.map((mins) => (
            <button
              key={mins}
              onClick={() => setForm({ ...form, duration_minutes: mins })}
              className={cn(
                'px-4 py-2 rounded-xl border text-sm font-medium transition-all',
                form.duration_minutes === mins
                  ? 'bg-primary text-white border-primary'
                  : 'bg-white border-border hover:bg-muted'
              )}
            >
              {mins}m
            </button>
          ))}
          <div className="flex items-center gap-1.5">
            <Input
              type="number"
              placeholder="Custom"
              className="w-20 h-9 text-sm"
              value={form.duration_minutes}
              onChange={(e) => setForm({ ...form, duration_minutes: Number(e.target.value) })}
              min={1}
              max={300}
            />
            <span className="text-xs text-muted-foreground">min</span>
          </div>
        </div>
      </div>

      {/* Details form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl border border-border p-4 space-y-4">
        <div className="space-y-1.5">
          <Label>Title (optional)</Label>
          <Input
            placeholder={selectedType?.label || 'Workout name'}
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
          />
        </div>
        <div className="space-y-1.5">
          <Label>Calories burned (optional)</Label>
          <Input
            type="number"
            placeholder="e.g. 250"
            value={form.calories_burned}
            onChange={(e) => setForm({ ...form, calories_burned: e.target.value })}
            min={0}
          />
        </div>
        <div className="space-y-1.5">
          <Label>Notes (optional)</Label>
          <Textarea
            placeholder="How did it feel? Any wins?"
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
            rows={2}
          />
        </div>
        <Button type="submit" className="w-full" disabled={isLoading}>
          {isLoading ? 'Logging...' : `Log ${form.duration_minutes}min ${selectedType?.label || 'workout'}`}
        </Button>
      </form>

      <EncouragementBanner />
    </div>
  )
}

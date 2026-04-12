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
import { MEAL_TYPES } from '@/lib/constants'
import { ArrowLeft, Star, Camera } from 'lucide-react'
import type { MealType } from '@/types'

const QUICK_MEALS = [
  { title: 'Greek Yogurt with Berries', calories: 220, protein: 18, carbs: 28, fat: 4, meal_type: 'breakfast' },
  { title: 'Grilled Chicken Salad', calories: 380, protein: 42, carbs: 18, fat: 14, meal_type: 'lunch' },
  { title: 'Protein Bar', calories: 200, protein: 20, carbs: 22, fat: 7, meal_type: 'snack' },
  { title: 'Eggs & Avocado Toast', calories: 420, protein: 22, carbs: 35, fat: 21, meal_type: 'breakfast' },
  { title: 'Salmon with Rice', calories: 520, protein: 45, carbs: 48, fat: 14, meal_type: 'dinner' },
]

interface MealForm {
  title: string
  meal_type: MealType
  calories: string
  protein: string
  carbs: string
  fat: string
  notes: string
}

const initialForm: MealForm = {
  title: '',
  meal_type: 'breakfast',
  calories: '',
  protein: '',
  carbs: '',
  fat: '',
  notes: '',
}

export default function AddMealPage() {
  const router = useRouter()
  const [form, setForm] = useState<MealForm>(initialForm)
  const [isLoading, setIsLoading] = useState(false)
  const [showSuccess, setShowSuccess] = useState(false)

  const applyQuickMeal = (meal: typeof QUICK_MEALS[0]) => {
    setForm({
      title: meal.title,
      meal_type: meal.meal_type as MealType,
      calories: String(meal.calories),
      protein: String(meal.protein),
      carbs: String(meal.carbs),
      fat: String(meal.fat),
      notes: '',
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    // In production: save to Supabase
    await new Promise(r => setTimeout(r, 600))
    setIsLoading(false)
    setShowSuccess(true)
    setTimeout(() => router.push('/dashboard'), 1500)
  }

  const isValid = form.title && form.calories && form.protein

  if (showSuccess) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4 animate-fade-in">
        <div className="text-5xl animate-celebrate">🎉</div>
        <h2 className="text-xl font-bold text-foreground">Meal logged!</h2>
        <EncouragementBanner message="You showed up today. That matters." variant="card" className="w-full max-w-sm" />
      </div>
    )
  }

  return (
    <div className="space-y-5 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href="/dashboard">
          <Button variant="ghost" size="icon-sm"><ArrowLeft className="w-4 h-4" /></Button>
        </Link>
        <div>
          <h1 className="text-xl font-semibold text-foreground">Log a meal</h1>
          <p className="text-xs text-muted-foreground">Keep it simple — protein matters most</p>
        </div>
      </div>

      {/* Meal type selector */}
      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
        {MEAL_TYPES.map(({ value, label, emoji }) => (
          <button
            key={value}
            onClick={() => setForm({ ...form, meal_type: value as MealType })}
            className={cn(
              'flex-shrink-0 flex items-center gap-1.5 px-3 py-2 rounded-xl border text-sm font-medium transition-all',
              form.meal_type === value
                ? 'bg-primary text-white border-primary'
                : 'bg-white border-border text-muted-foreground hover:bg-muted'
            )}
          >
            <span>{emoji}</span> {label}
          </button>
        ))}
      </div>

      {/* Favorite meals quick-add */}
      <div>
        <div className="flex items-center gap-2 mb-2">
          <Star className="w-4 h-4 text-closer-gold" />
          <h2 className="text-sm font-semibold text-foreground">Quick-add favorites</h2>
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {QUICK_MEALS.map((meal) => (
            <button
              key={meal.title}
              onClick={() => applyQuickMeal(meal)}
              className="flex-shrink-0 bg-white border border-border rounded-xl px-3 py-2 text-left hover:bg-muted/50 transition-colors min-w-[140px]"
            >
              <p className="text-xs font-medium text-foreground truncate">{meal.title}</p>
              <p className="text-[10px] text-muted-foreground mt-0.5">{meal.calories} cal · {meal.protein}g protein</p>
            </button>
          ))}
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl border border-border p-4 space-y-4">
        <div className="space-y-1.5">
          <Label>Meal name</Label>
          <Input
            placeholder="e.g. Grilled chicken and rice"
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            required
          />
        </div>

        {/* Macro inputs — protein first */}
        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1.5 col-span-2">
            <Label className="text-closer-teal font-semibold">Protein (g) ★</Label>
            <Input
              type="number"
              placeholder="e.g. 35"
              value={form.protein}
              onChange={(e) => setForm({ ...form, protein: e.target.value })}
              required
              min={0}
              className="border-closer-teal/30 focus-visible:ring-closer-teal"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Calories</Label>
            <Input
              type="number"
              placeholder="e.g. 450"
              value={form.calories}
              onChange={(e) => setForm({ ...form, calories: e.target.value })}
              required
              min={0}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Carbs (g)</Label>
            <Input
              type="number"
              placeholder="e.g. 40"
              value={form.carbs}
              onChange={(e) => setForm({ ...form, carbs: e.target.value })}
              min={0}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Fat (g)</Label>
            <Input
              type="number"
              placeholder="e.g. 12"
              value={form.fat}
              onChange={(e) => setForm({ ...form, fat: e.target.value })}
              min={0}
            />
          </div>
        </div>

        <div className="space-y-1.5">
          <Label>Notes (optional)</Label>
          <Textarea
            placeholder="Any notes about this meal..."
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
            rows={2}
          />
        </div>

        {/* Photo placeholder */}
        <button
          type="button"
          className="w-full border-2 border-dashed border-border rounded-xl p-4 flex items-center justify-center gap-2 text-sm text-muted-foreground hover:bg-muted/50 transition-colors"
        >
          <Camera className="w-4 h-4" />
          Add photo (coming soon)
        </button>

        <Button type="submit" className="w-full" disabled={!isValid || isLoading}>
          {isLoading ? 'Logging...' : 'Log meal'}
        </Button>
      </form>
    </div>
  )
}

'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Progress } from '@/components/ui/progress'
import { cn } from '@/lib/utils'
import { PRIMARY_GOALS, RELATIONSHIP_TYPES, DEFAULT_PROTEIN, DEFAULT_WATER, DEFAULT_WORKOUTS } from '@/lib/constants'
import { ChevronRight, ChevronLeft, Check } from 'lucide-react'
import type { OnboardingData, PrimaryGoal, RelationshipType } from '@/types'

const TOTAL_STEPS = 6

const initialData: OnboardingData = {
  full_name: '',
  primary_goal: 'lose_weight',
  starting_weight: undefined,
  target_weight: undefined,
  daily_calorie_target: 1800,
  daily_protein_target: DEFAULT_PROTEIN,
  daily_water_target: DEFAULT_WATER,
  weekly_workout_target: DEFAULT_WORKOUTS,
  track_weight: true,
  track_measurements: false,
  invite_supporter: false,
  supporter_email: '',
  supporter_relationship: 'partner',
  reminder_enabled: true,
}

export default function OnboardingPage() {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [data, setData] = useState<OnboardingData>(initialData)
  const [isFinishing, setIsFinishing] = useState(false)

  const progress = ((step - 1) / (TOTAL_STEPS - 1)) * 100

  const next = () => setStep(s => Math.min(s + 1, TOTAL_STEPS))
  const back = () => setStep(s => Math.max(s - 1, 1))

  const finish = async () => {
    setIsFinishing(true)
    // In production: save to Supabase
    await new Promise(r => setTimeout(r, 1000))
    router.push('/dashboard')
  }

  return (
    <div className="min-h-screen bg-closer-cream flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-3">
            <span className="text-sm text-muted-foreground">Step {step} of {TOTAL_STEPS}</span>
            <button onClick={() => router.push('/dashboard')} className="text-xs text-muted-foreground underline">
              Skip for now
            </button>
          </div>
          <Progress value={progress} indicatorClassName="bg-closer-sage" />
        </div>

        {/* Step content */}
        <div className="bg-white rounded-2xl border border-border p-6 shadow-sm min-h-[400px] flex flex-col">
          {step === 1 && (
            <StepName data={data} onChange={(v) => setData({ ...data, full_name: v })} />
          )}
          {step === 2 && (
            <StepGoal data={data} onChange={(v) => setData({ ...data, primary_goal: v })} />
          )}
          {step === 3 && (
            <StepTargets data={data} onChange={(updates) => setData({ ...data, ...updates })} />
          )}
          {step === 4 && (
            <StepTracking data={data} onChange={(updates) => setData({ ...data, ...updates })} />
          )}
          {step === 5 && (
            <StepSupporter data={data} onChange={(updates) => setData({ ...data, ...updates })} />
          )}
          {step === 6 && (
            <StepReminders data={data} onChange={(v) => setData({ ...data, reminder_enabled: v })} />
          )}

          {/* Nav */}
          <div className="flex gap-3 mt-auto pt-6">
            {step > 1 && (
              <Button variant="outline" onClick={back} className="flex-1">
                <ChevronLeft className="w-4 h-4 mr-1" /> Back
              </Button>
            )}
            {step < TOTAL_STEPS ? (
              <Button onClick={next} className="flex-1">
                Continue <ChevronRight className="w-4 h-4 ml-1" />
              </Button>
            ) : (
              <Button onClick={finish} disabled={isFinishing} className="flex-1">
                {isFinishing ? 'Setting up...' : (
                  <><Check className="w-4 h-4 mr-1" /> Let's go!</>
                )}
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

// --- Step Components ---

function StepName({ data, onChange }: { data: OnboardingData; onChange: (v: string) => void }) {
  return (
    <div className="flex flex-col gap-4 flex-1">
      <div>
        <h2 className="text-xl font-bold text-foreground mb-1">What's your name?</h2>
        <p className="text-sm text-muted-foreground">We'll use this to personalize your experience.</p>
      </div>
      <div className="space-y-2">
        <Label htmlFor="name">First name</Label>
        <Input
          id="name"
          placeholder="e.g. Sarah"
          value={data.full_name}
          onChange={(e) => onChange(e.target.value)}
          autoFocus
        />
      </div>
      {data.full_name && (
        <div className="bg-closer-sage/10 rounded-xl p-3 text-sm text-closer-sage">
          Hey {data.full_name}! We're glad you're here. Let's build something that actually works for you.
        </div>
      )}
    </div>
  )
}

function StepGoal({ data, onChange }: { data: OnboardingData; onChange: (v: PrimaryGoal) => void }) {
  return (
    <div className="flex flex-col gap-4 flex-1">
      <div>
        <h2 className="text-xl font-bold text-foreground mb-1">What's your main goal?</h2>
        <p className="text-sm text-muted-foreground">Choose the one that resonates most right now.</p>
      </div>
      <div className="grid gap-2">
        {PRIMARY_GOALS.map(({ value, label, emoji }) => (
          <button
            key={value}
            onClick={() => onChange(value as PrimaryGoal)}
            className={cn(
              'flex items-center gap-3 p-3.5 rounded-xl border text-left transition-all text-sm font-medium',
              data.primary_goal === value
                ? 'border-primary bg-primary/5 text-primary'
                : 'border-border bg-background text-foreground hover:bg-muted'
            )}
          >
            <span className="text-xl">{emoji}</span>
            {label}
            {data.primary_goal === value && <Check className="w-4 h-4 ml-auto" />}
          </button>
        ))}
      </div>
    </div>
  )
}

function StepTargets({ data, onChange }: { data: OnboardingData; onChange: (v: Partial<OnboardingData>) => void }) {
  return (
    <div className="flex flex-col gap-4 flex-1">
      <div>
        <h2 className="text-xl font-bold text-foreground mb-1">Set your daily targets</h2>
        <p className="text-sm text-muted-foreground">We've set smart defaults. Adjust anytime.</p>
      </div>
      <div className="space-y-3">
        <div className="space-y-1.5">
          <Label>Daily protein target (grams)</Label>
          <Input
            type="number"
            value={data.daily_protein_target}
            onChange={(e) => onChange({ daily_protein_target: Number(e.target.value) })}
            min={50} max={300}
          />
          <p className="text-xs text-muted-foreground">Recommended: body weight in lbs ÷ 1 = protein grams</p>
        </div>
        <div className="space-y-1.5">
          <Label>Daily water target (oz)</Label>
          <Input
            type="number"
            value={data.daily_water_target}
            onChange={(e) => onChange({ daily_water_target: Number(e.target.value) })}
            min={32} max={200}
          />
        </div>
        <div className="space-y-1.5">
          <Label>Workouts per week</Label>
          <div className="flex gap-2">
            {[2, 3, 4, 5, 6].map((n) => (
              <button
                key={n}
                onClick={() => onChange({ weekly_workout_target: n })}
                className={cn(
                  'flex-1 py-2 rounded-xl border text-sm font-medium transition-all',
                  data.weekly_workout_target === n
                    ? 'bg-primary text-white border-primary'
                    : 'border-border hover:bg-muted'
                )}
              >
                {n}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function StepTracking({ data, onChange }: { data: OnboardingData; onChange: (v: Partial<OnboardingData>) => void }) {
  return (
    <div className="flex flex-col gap-4 flex-1">
      <div>
        <h2 className="text-xl font-bold text-foreground mb-1">What would you like to track?</h2>
        <p className="text-sm text-muted-foreground">You can always change these in settings.</p>
      </div>

      {[
        { key: 'track_weight', label: 'Body weight', emoji: '⚖️', desc: 'Weekly weigh-ins, trend over time' },
        { key: 'track_measurements', label: 'Measurements', emoji: '📏', desc: 'Waist, hips, and more' },
      ].map(({ key, label, emoji, desc }) => {
        const isOn = data[key as keyof OnboardingData] as boolean
        return (
          <button
            key={key}
            onClick={() => onChange({ [key]: !isOn })}
            className={cn(
              'flex items-center gap-3 p-4 rounded-xl border text-left transition-all',
              isOn ? 'border-primary bg-primary/5' : 'border-border hover:bg-muted'
            )}
          >
            <span className="text-2xl">{emoji}</span>
            <div className="flex-1">
              <div className="text-sm font-medium text-foreground">{label}</div>
              <div className="text-xs text-muted-foreground mt-0.5">{desc}</div>
            </div>
            <div className={cn(
              'w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors',
              isOn ? 'border-primary bg-primary' : 'border-border'
            )}>
              {isOn && <Check className="w-3 h-3 text-white" />}
            </div>
          </button>
        )
      })}

      <div className="bg-muted rounded-xl p-3">
        <p className="text-xs text-muted-foreground">
          💡 <strong>Tip:</strong> Focus on habits first, not numbers. Weight naturally follows consistency.
        </p>
      </div>
    </div>
  )
}

function StepSupporter({ data, onChange }: { data: OnboardingData; onChange: (v: Partial<OnboardingData>) => void }) {
  return (
    <div className="flex flex-col gap-4 flex-1">
      <div>
        <h2 className="text-xl font-bold text-foreground mb-1">Invite a supporter?</h2>
        <p className="text-sm text-muted-foreground">Having one trusted person in your corner makes a real difference.</p>
      </div>

      <div className="flex gap-3">
        <button
          onClick={() => onChange({ invite_supporter: true })}
          className={cn(
            'flex-1 py-3 rounded-xl border text-sm font-medium transition-all',
            data.invite_supporter ? 'bg-primary text-white border-primary' : 'border-border hover:bg-muted'
          )}
        >
          Yes, I'd like support
        </button>
        <button
          onClick={() => onChange({ invite_supporter: false })}
          className={cn(
            'flex-1 py-3 rounded-xl border text-sm font-medium transition-all',
            !data.invite_supporter ? 'bg-muted border-border' : 'border-border hover:bg-muted'
          )}
        >
          Solo for now
        </button>
      </div>

      {data.invite_supporter && (
        <div className="space-y-3 animate-fade-in">
          <div className="space-y-1.5">
            <Label>Their email address</Label>
            <Input
              type="email"
              placeholder="partner@example.com"
              value={data.supporter_email}
              onChange={(e) => onChange({ supporter_email: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Relationship</Label>
            <div className="grid grid-cols-2 gap-2">
              {RELATIONSHIP_TYPES.map(({ value, label }) => (
                <button
                  key={value}
                  onClick={() => onChange({ supporter_relationship: value as RelationshipType })}
                  className={cn(
                    'py-2 px-3 rounded-xl border text-xs font-medium transition-all text-left',
                    data.supporter_relationship === value
                      ? 'border-primary bg-primary/5 text-primary'
                      : 'border-border hover:bg-muted'
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
          <p className="text-xs text-muted-foreground">
            They'll only see what you choose to share. They can cheer you on — never shame you.
          </p>
        </div>
      )}
    </div>
  )
}

function StepReminders({ data, onChange }: { data: OnboardingData; onChange: (v: boolean) => void }) {
  return (
    <div className="flex flex-col gap-4 flex-1">
      <div>
        <h2 className="text-xl font-bold text-foreground mb-1">Gentle reminders?</h2>
        <p className="text-sm text-muted-foreground">We keep them warm and infrequent. No spam, no guilt.</p>
      </div>

      <div className="flex gap-3">
        {[
          { value: true, label: 'Yes please', emoji: '🔔' },
          { value: false, label: 'No thanks', emoji: '🔕' },
        ].map(({ value, label, emoji }) => (
          <button
            key={label}
            onClick={() => onChange(value)}
            className={cn(
              'flex-1 flex flex-col items-center gap-2 py-4 rounded-xl border text-sm font-medium transition-all',
              data.reminder_enabled === value ? 'border-primary bg-primary/5 text-primary' : 'border-border hover:bg-muted'
            )}
          >
            <span className="text-2xl">{emoji}</span>
            {label}
          </button>
        ))}
      </div>

      <div className="bg-closer-sage/10 rounded-2xl p-4 space-y-2">
        <p className="text-sm font-medium text-closer-sage">You're all set, {data.full_name || 'friend'}.</p>
        <p className="text-xs text-muted-foreground leading-relaxed">
          Your dashboard is ready. Start simple — log one meal, drink some water, and you're already winning today.
        </p>
      </div>

      <div className="text-center">
        <p className="text-sm italic text-muted-foreground">"You're closer than you think."</p>
      </div>
    </div>
  )
}

'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { cn } from '@/lib/utils'
import { RELATIONSHIP_TYPES } from '@/lib/constants'
import { ArrowLeft, CheckCircle2, Copy, UserPlus, Heart, Lock, Eye } from 'lucide-react'
import type { RelationshipType } from '@/types'

const SUPPORTER_CAN = [
  { icon: Eye, text: 'View your daily progress summary' },
  { icon: Heart, text: 'Send you encouragement and reactions' },
  { icon: CheckCircle2, text: 'Celebrate your streaks and milestones' },
]

const SUPPORTER_CANNOT = [
  'See specific meal details (unless you share)',
  'Post negative comments or pressure you',
  'Track or criticize your numbers',
]

export default function InvitePage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [relationship, setRelationship] = useState<RelationshipType>('partner')
  const [message, setMessage] = useState('Hey! I\'m using Closer to work on my health goals and would love your support. Join so you can cheer me on!')
  const [isLoading, setIsLoading] = useState(false)
  const [inviteSent, setInviteSent] = useState(false)

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email) return
    setIsLoading(true)
    await new Promise(r => setTimeout(r, 800))
    setIsLoading(false)
    setInviteSent(true)
  }

  if (inviteSent) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-5 animate-fade-in text-center px-4">
        <div className="text-5xl animate-celebrate">🤝</div>
        <div>
          <h2 className="text-xl font-bold text-foreground">Invite sent!</h2>
          <p className="text-sm text-muted-foreground mt-2">
            We sent {email} an invite to join your support circle.
          </p>
        </div>
        <div className="bg-closer-sage/10 border border-closer-sage/20 rounded-2xl p-4 w-full max-w-sm">
          <p className="text-sm text-closer-sage font-medium">Not alone anymore.</p>
          <p className="text-xs text-muted-foreground mt-1">Having one trusted person in your corner significantly improves consistency.</p>
        </div>
        <Button onClick={() => router.push('/supporter')}>
          Go to support dashboard
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="flex items-center gap-3">
        <Link href="/supporter">
          <Button variant="ghost" size="icon-sm"><ArrowLeft className="w-4 h-4" /></Button>
        </Link>
        <div>
          <h1 className="text-xl font-semibold text-foreground">Invite a supporter</h1>
          <p className="text-xs text-muted-foreground">Private, controlled, supportive</p>
        </div>
      </div>

      {/* What supporters can do */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">Your supporter can:</h2>
        <div className="space-y-2 mb-4">
          {SUPPORTER_CAN.map(({ icon: Icon, text }) => (
            <div key={text} className="flex items-center gap-2">
              <Icon className="w-4 h-4 text-closer-sage flex-shrink-0" />
              <p className="text-sm text-foreground">{text}</p>
            </div>
          ))}
        </div>
        <div className="pt-3 border-t border-border">
          <div className="flex items-start gap-2 mb-2">
            <Lock className="w-4 h-4 text-muted-foreground mt-0.5 flex-shrink-0" />
            <p className="text-xs font-medium text-muted-foreground">They cannot:</p>
          </div>
          <ul className="space-y-1">
            {SUPPORTER_CANNOT.map((item) => (
              <li key={item} className="text-xs text-muted-foreground pl-6 list-disc">{item}</li>
            ))}
          </ul>
        </div>
      </div>

      {/* Invite form */}
      <form onSubmit={handleSend} className="bg-white rounded-2xl border border-border p-4 space-y-4">
        <div className="space-y-1.5">
          <Label>Their email address</Label>
          <Input
            type="email"
            placeholder="partner@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </div>

        <div className="space-y-1.5">
          <Label>Your relationship</Label>
          <div className="grid grid-cols-2 gap-2">
            {RELATIONSHIP_TYPES.map(({ value, label }) => (
              <button
                key={value}
                type="button"
                onClick={() => setRelationship(value as RelationshipType)}
                className={cn(
                  'py-2.5 px-3 rounded-xl border text-xs font-medium text-left transition-all',
                  relationship === value
                    ? 'bg-primary/10 border-primary text-primary'
                    : 'border-border hover:bg-muted text-foreground'
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="space-y-1.5">
          <Label>Personal message (optional)</Label>
          <textarea
            className="flex min-h-[80px] w-full rounded-xl border border-input bg-background px-4 py-3 text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring resize-none"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={3}
          />
        </div>

        <Button type="submit" className="w-full" disabled={!email || isLoading}>
          <UserPlus className="w-4 h-4 mr-2" />
          {isLoading ? 'Sending invite...' : 'Send invite'}
        </Button>
      </form>

      {/* Or copy link */}
      <div className="bg-white rounded-2xl border border-border p-4">
        <h2 className="text-sm font-semibold text-foreground mb-3">Or share a link</h2>
        <div className="flex gap-2">
          <input
            readOnly
            value="https://closer.app/invite/abc123xyz"
            className="flex-1 h-10 px-3 rounded-xl border border-input bg-muted text-xs text-muted-foreground"
          />
          <Button variant="outline" size="icon" onClick={() => navigator.clipboard?.writeText('https://closer.app/invite/abc123xyz')}>
            <Copy className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}

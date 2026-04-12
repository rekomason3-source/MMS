import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { CheckCircle2, Heart, Lock, TrendingUp, Users, Sparkles } from 'lucide-react'

const features = [
  {
    icon: TrendingUp,
    title: 'Track what matters',
    description: 'Calories, protein, water, workouts, sleep, and weight — all in one calm, clean space.',
  },
  {
    icon: Lock,
    title: 'Completely private',
    description: 'Your progress is yours. No public feed, no comparisons, no judgment.',
  },
  {
    icon: Heart,
    title: 'Built-in support',
    description: 'Invite your partner, friend, or coach to cheer you on — on your terms.',
  },
  {
    icon: Sparkles,
    title: 'Encouragement, not pressure',
    description: "We celebrate your effort and consistency. No guilt. No shame. No punishment.",
  },
]

const testimonials = [
  {
    quote: "I've tried every app out there. Closer is the first one that actually made me feel supported instead of judged.",
    name: 'Maya R.',
    detail: 'Lost 22 lbs over 4 months',
  },
  {
    quote: 'My husband and I use it together. Seeing each other\u2019s streaks keeps us both going.',
    name: 'Danielle K.',
    detail: 'Couple\u2019s accountability',
  },
  {
    quote: 'I quit three other apps because they made me feel terrible about myself. Closer is different.',
    name: 'James T.',
    detail: 'Down 30 lbs',
  },
]

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-closer-cream">
      {/* Nav */}
      <nav className="sticky top-0 z-40 border-b border-border bg-closer-cream/90 backdrop-blur-sm">
        <div className="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center">
              <span className="text-white text-xs font-bold">C</span>
            </div>
            <span className="font-semibold text-foreground">Closer</span>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/login">
              <Button variant="ghost" size="sm">Sign in</Button>
            </Link>
            <Link href="/signup">
              <Button size="sm">Get started free</Button>
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="max-w-5xl mx-auto px-4 pt-20 pb-16 text-center">
        <div className="inline-flex items-center gap-2 bg-closer-sage/10 text-closer-sage text-xs font-medium px-3 py-1.5 rounded-full mb-6">
          <Sparkles className="w-3.5 h-3.5" />
          Private. Supportive. Effective.
        </div>
        <h1 className="text-5xl sm:text-6xl font-bold text-foreground leading-tight mb-6">
          Progress without<br />
          <span className="text-primary">pressure.</span>
        </h1>
        <p className="text-xl text-muted-foreground max-w-xl mx-auto mb-8 leading-relaxed">
          Track your health goals with encouragement, not judgment.
          Built for real people who want consistent progress — not perfection.
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link href="/signup">
            <Button size="xl" className="w-full sm:w-auto">
              Start for free →
            </Button>
          </Link>
          <Link href="/dashboard">
            <Button size="xl" variant="outline" className="w-full sm:w-auto">
              See a demo
            </Button>
          </Link>
        </div>
        <p className="text-sm text-muted-foreground mt-4">No credit card required. Free forever.</p>
      </section>

      {/* Social proof strip */}
      <div className="bg-white border-y border-border py-4">
        <div className="max-w-4xl mx-auto px-4 flex flex-wrap items-center justify-center gap-6 text-sm text-muted-foreground">
          {[
            '🌱 Built for real life',
            '🔒 100% private',
            '❤️ Shame-free tracking',
            '💪 Protein-first nutrition',
            '👫 Partner support',
          ].map((item) => (
            <span key={item} className="font-medium">{item}</span>
          ))}
        </div>
      </div>

      {/* Features */}
      <section className="max-w-5xl mx-auto px-4 py-20">
        <h2 className="text-3xl font-bold text-center text-foreground mb-3">
          Everything you need. Nothing you don't.
        </h2>
        <p className="text-center text-muted-foreground mb-12 max-w-md mx-auto">
          Closer is designed to be fast, simple, and emotionally intelligent.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          {features.map(({ icon: Icon, title, description }) => (
            <div
              key={title}
              className="bg-white rounded-2xl p-6 border border-border hover:shadow-md transition-shadow"
            >
              <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center mb-4">
                <Icon className="w-5 h-5 text-primary" />
              </div>
              <h3 className="font-semibold text-foreground mb-2">{title}</h3>
              <p className="text-sm text-muted-foreground leading-relaxed">{description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* What you track */}
      <section className="bg-white border-y border-border py-16">
        <div className="max-w-5xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center text-foreground mb-12">
            Track the things that actually move the needle
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {[
              { emoji: '🥩', label: 'Protein', sub: 'Your top priority' },
              { emoji: '🔥', label: 'Calories', sub: 'Without obsession' },
              { emoji: '💧', label: 'Water', sub: 'Consistent hydration' },
              { emoji: '🏃', label: 'Workouts', sub: 'All movement counts' },
              { emoji: '😴', label: 'Sleep', sub: 'Recovery matters' },
              { emoji: '⚖️', label: 'Weight', sub: 'Trend, not numbers' },
              { emoji: '😊', label: 'Mood', sub: 'Emotional check-ins' },
              { emoji: '🔥', label: 'Streaks', sub: 'Motivating, not punishing' },
            ].map(({ emoji, label, sub }) => (
              <div key={label} className="text-center p-4 rounded-2xl bg-muted/50">
                <div className="text-3xl mb-2">{emoji}</div>
                <div className="font-semibold text-sm text-foreground">{label}</div>
                <div className="text-xs text-muted-foreground mt-0.5">{sub}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="max-w-5xl mx-auto px-4 py-20">
        <h2 className="text-3xl font-bold text-center text-foreground mb-12">
          Real people. Real progress.
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
          {testimonials.map(({ quote, name, detail }) => (
            <div key={name} className="bg-white rounded-2xl p-6 border border-border">
              <p className="text-sm text-foreground/80 italic leading-relaxed mb-4">"{quote}"</p>
              <div>
                <div className="font-semibold text-sm text-foreground">{name}</div>
                <div className="text-xs text-muted-foreground mt-0.5">{detail}</div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Pricing */}
      <section className="bg-muted/30 border-y border-border py-16">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold text-foreground mb-3">
            Start free. Upgrade when you're ready.
          </h2>
          <p className="text-muted-foreground mb-10">
            The core tracking experience is always free. Unlock partner sharing and advanced features with Plus.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-left">
            {/* Free */}
            <div className="bg-white rounded-2xl p-6 border border-border">
              <div className="text-lg font-bold text-foreground mb-1">Free</div>
              <div className="text-3xl font-bold text-foreground mb-4">$0 <span className="text-sm font-normal text-muted-foreground">/mo</span></div>
              <ul className="space-y-2.5">
                {['Daily dashboard', 'Meal & macro logging', 'Workout tracking', 'Water tracking', 'Streaks & badges', 'Weekly reviews', '30-day history'].map((f) => (
                  <li key={f} className="flex items-center gap-2 text-sm text-foreground">
                    <CheckCircle2 className="w-4 h-4 text-closer-sage flex-shrink-0" />
                    {f}
                  </li>
                ))}
              </ul>
              <Link href="/signup" className="mt-6 block">
                <Button variant="outline" className="w-full">Get started free</Button>
              </Link>
            </div>
            {/* Plus */}
            <div className="bg-primary rounded-2xl p-6 text-white relative overflow-hidden">
              <div className="absolute top-3 right-3 bg-white/20 text-white text-xs font-medium px-2 py-0.5 rounded-full">
                Most popular
              </div>
              <div className="text-lg font-bold mb-1">Closer Plus</div>
              <div className="text-3xl font-bold mb-4">$9.99 <span className="text-sm font-normal opacity-70">/mo</span></div>
              <ul className="space-y-2.5">
                {['Everything in Free', 'Partner / supporter sharing', 'Advanced progress charts', 'Full history', 'Custom goal targets', 'Smart reminders', 'Exportable reports', 'Priority support'].map((f) => (
                  <li key={f} className="flex items-center gap-2 text-sm text-white">
                    <CheckCircle2 className="w-4 h-4 text-white/80 flex-shrink-0" />
                    {f}
                  </li>
                ))}
              </ul>
              <Link href="/signup" className="mt-6 block">
                <Button variant="warm" className="w-full">Start 7-day trial</Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="max-w-2xl mx-auto px-4 py-20 text-center">
        <h2 className="text-4xl font-bold text-foreground mb-4">
          You're closer than you think.
        </h2>
        <p className="text-lg text-muted-foreground mb-8">
          Take the first step. No judgment. No pressure. Just progress.
        </p>
        <Link href="/signup">
          <Button size="xl">Create your free account →</Button>
        </Link>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-8">
        <div className="max-w-5xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-md bg-primary flex items-center justify-center">
              <span className="text-white text-xs font-bold">C</span>
            </div>
            <span className="font-semibold text-sm text-foreground">Closer</span>
          </div>
          <p className="text-xs text-muted-foreground">
            © 2025 Closer. Built with care for real people on real journeys.
          </p>
          <div className="flex gap-4 text-xs text-muted-foreground">
            <Link href="#" className="hover:text-foreground">Privacy</Link>
            <Link href="#" className="hover:text-foreground">Terms</Link>
          </div>
        </div>
      </footer>
    </div>
  )
}

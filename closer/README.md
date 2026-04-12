# Closer — Private Accountability App MVP

> **Progress without pressure. Support without shame.**

A private accountability app for people who want to reach health and lifestyle goals with encouragement, consistency, and trusted support from a partner, friend, or family member.

---

## Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 14 (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| UI Components | Custom (shadcn/ui-style) |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Charts | Recharts |
| Forms | React Hook Form + Zod |
| Icons | Lucide React |

---

## Quick Start (Local Development)

### 1. Install dependencies

```bash
cd closer
npm install
```

### 2. Set up environment

```bash
cp .env.local.example .env.local
```

Edit `.env.local` with your Supabase project credentials:

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

> **No Supabase yet?** The app runs in **demo mode** using mock data — no credentials required. Just run `npm run dev` and explore.

### 3. (Optional) Set up Supabase database

1. Create a new project at [supabase.com](https://supabase.com)
2. In the SQL editor, run the contents of `supabase/schema.sql`
3. Enable Auth → Email provider
4. Set Site URL in Auth settings to `http://localhost:3000`

### 4. Run the development server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## App Screens

| Route | Screen |
|---|---|
| `/` | Landing page |
| `/signup` | Create account |
| `/login` | Sign in |
| `/onboarding` | 6-step setup wizard |
| `/dashboard` | Daily dashboard (main screen) |
| `/log` | Log menu |
| `/log/meal` | Add meal |
| `/log/workout` | Add workout |
| `/log/water` | Log water intake |
| `/progress` | Progress charts & trends |
| `/weekly-review` | Weekly review flow |
| `/supporter` | Supporter dashboard |
| `/invite` | Invite a supporter |
| `/goals` | Goals & settings |
| `/milestones` | Badges & achievements |

---

## Project Structure

```
closer/
├── app/                    # Next.js App Router pages
│   ├── page.tsx            # Landing page
│   ├── layout.tsx          # Root layout
│   ├── login/              # Auth
│   ├── signup/
│   ├── onboarding/         # 6-step onboarding
│   ├── dashboard/          # Main app
│   ├── log/                # Logging screens
│   │   ├── meal/
│   │   ├── workout/
│   │   └── water/
│   ├── progress/           # Charts & trends
│   ├── weekly-review/
│   ├── supporter/          # Support dashboard
│   ├── invite/
│   ├── goals/              # Settings
│   └── milestones/         # Badges
├── components/
│   ├── ui/                 # Base UI components
│   ├── shared/             # Shared app components
│   │   ├── bottom-nav.tsx
│   │   ├── macro-ring.tsx  # SVG progress ring
│   │   ├── stat-card.tsx
│   │   └── streak-badge.tsx
│   └── encouragement/      # Encouragement engine UI
├── lib/
│   ├── utils.ts            # Helpers
│   ├── constants.ts        # App constants & config
│   ├── encouragement.ts    # Message engine (core differentiator)
│   ├── mock-data.ts        # Demo seed data
│   └── supabase/           # Supabase client
├── types/
│   └── index.ts            # All TypeScript types
└── supabase/
    └── schema.sql          # Full database schema
```

---

## Architecture Decisions

### Why Next.js App Router?
- Server components for fast initial loads
- Easy API routes for future webhook handling (Stripe, push notifications)
- Great SEO for landing page
- Single codebase for web + future PWA

### Why Supabase?
- Realtime subscriptions for live supporter updates
- Built-in auth (email, OAuth ready)
- Row-level security for privacy-first architecture
- Storage for progress photos
- Easy to migrate to self-hosted if needed

### Why local state (vs Redux/Zustand) for MVP?
- Fewer moving parts
- Faster iteration
- Zustand/React Query can be added when data complexity grows

---

## Data Model

The full schema is in `supabase/schema.sql`. Key tables:

- `profiles` — User profile data
- `user_goals` — Daily/weekly targets
- `meals` — Logged food entries with macros
- `workouts` — Exercise sessions
- `hydration_logs` — Water intake
- `weight_logs` — Weight entries
- `mood_logs` — Daily mood/energy
- `streaks` — Per-type streak tracking
- `badges` + `user_badges` — Achievement system
- `supporter_relationships` — Privacy-controlled sharing
- `encouragement_messages` — Supporter → user messages
- `weekly_summaries` — Auto-generated weekly reviews
- `subscriptions` — Stripe-ready plan tracking

---

## Encouragement Engine

The encouragement engine (`lib/encouragement.ts`) is a core product differentiator.

It provides **context-aware, shame-free messages** triggered by user actions:

```typescript
// Trigger types
'first_meal_logged' | 'protein_goal_hit' | 'workout_logged' |
'streak_3_day' | 'streak_7_day' | 'returning_after_gap' | ...

// Usage
const message = getEncouragementMessage('returning_after_gap')
// → "You're back. A gap in the log isn't a failure — coming back is what matters."
```

Key design principles:
- Celebrates **effort and consistency**, not just outcomes
- Handles **return after gap** with gentleness, not guilt
- Avoids competitive language, shame, or pressure
- Supporters get a separate message set for privacy boundaries

---

## Monetization Model

### Free Plan
- Daily dashboard
- Meal, workout, water logging
- Streaks & badges
- Weekly review
- 30-day history

### Closer Plus ($9.99/mo · $79.99/yr)
- Everything in Free
- Partner/supporter sharing (up to 2)
- Advanced progress charts
- Full history (365 days)
- Smart reminders
- Exportable reports

### Family Plan ($16.99/mo)
- Up to 5 linked users
- Shared accountability circle
- Family dashboard

### Coach Plan ($29.99/mo)
- Coach + up to 20 clients
- Client progress dashboards
- Notes & custom messaging
- White-label ready

---

## Phase 2 Feature Roadmap

### Immediate (Month 1-2)
- [ ] Supabase Auth integration (live login/signup)
- [ ] Real data persistence (meals, workouts, weight)
- [ ] Push notifications (web + mobile)
- [ ] Stripe billing integration

### Near-term (Month 3-4)
- [ ] AI food photo estimation (GPT-4 Vision)
- [ ] AI weekly recap generation
- [ ] Apple Health / Google Fit sync
- [ ] Progress photo comparison view
- [ ] Smart re-engagement after gaps

### Growth (Month 5-6)
- [ ] Coach dashboard
- [ ] Family plan with shared circle
- [ ] Referral program
- [ ] Challenge mode (30-day challenges)
- [ ] GLP-1 support mode (behavior + habit tracking)
- [ ] Postpartum mode (specialized goals + encouragement)

### Scale (Month 7+)
- [ ] Grocery planning + meal suggestions
- [ ] Wearable integrations (Apple Watch, Fitbit, Oura)
- [ ] Admin analytics dashboard
- [ ] White-label for trainers & coaches
- [ ] Accountability circles / group challenges
- [ ] API for third-party integrations

---

## Startup Positioning

**Category:** Private health accountability app

**Target:** Busy adults (especially parents and couples) who want to improve their health but feel overwhelmed, judged, or unsupported by existing apps.

**Positioning statement:**
> Closer is the private accountability app for people who want real health progress — with the encouragement of someone who knows them, not the judgment of a public feed.

### Tagline options

1. **"Progress without pressure."** — Clean, direct, differentiating
2. **"Your health journey. Your pace. Your people."** — Relationship-focused
3. **"Track. Improve. Feel supported."** — Functional clarity
4. **"Built for real life. Designed for real people."** — Accessible, warm
5. **"You're closer than you think."** — Emotional, brand voice aligned
6. **"Private support for public goals."** — Clarity + contrast

**Recommended tagline:** *Progress without pressure. Support without shame.*

---

## Safety & Wellness Guidelines

This app is designed to:
- Encourage gradual, sustainable progress
- Support consistency over extremes
- Provide accountability without pressure
- Celebrate non-scale victories

This app intentionally avoids:
- Extreme calorie restriction language
- Guilt-based messaging
- Punishing streaks (missed days are handled gently)
- Public comparisons or leaderboards
- Obsessive behavioral reinforcement patterns

---

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a PR with a clear description

---

Built with care for real people on real journeys. 🌱

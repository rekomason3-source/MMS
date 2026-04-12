import Link from 'next/link'
import { Utensils, Dumbbell, Droplets, Moon, Scale, Smile } from 'lucide-react'

const logOptions = [
  { href: '/log/meal', icon: Utensils, label: 'Log a meal', desc: 'Food, snacks, drinks', color: 'bg-closer-sage/15 text-closer-sage', emoji: '🍽️' },
  { href: '/log/workout', icon: Dumbbell, label: 'Log workout', desc: 'Any movement counts', color: 'bg-closer-teal/15 text-closer-teal', emoji: '🏃' },
  { href: '/log/water', icon: Droplets, label: 'Log water', desc: 'Stay hydrated', color: 'bg-blue-100 text-blue-500', emoji: '💧' },
]

export default function LogIndexPage() {
  return (
    <div className="space-y-4 animate-fade-in">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Log</h1>
        <p className="text-sm text-muted-foreground">Quick-add anything to your day</p>
      </div>

      <div className="space-y-3">
        {logOptions.map(({ href, icon: Icon, label, desc, color, emoji }) => (
          <Link key={href} href={href}>
            <div className="bg-white border border-border rounded-2xl p-4 flex items-center gap-4 hover:shadow-sm transition-all active:scale-[0.99] cursor-pointer">
              <div className={`w-12 h-12 rounded-2xl ${color} flex items-center justify-center text-xl flex-shrink-0`}>
                {emoji}
              </div>
              <div>
                <p className="font-semibold text-foreground">{label}</p>
                <p className="text-sm text-muted-foreground">{desc}</p>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  )
}

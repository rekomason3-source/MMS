'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard,
  TrendingUp,
  PlusCircle,
  Users,
  Target,
} from 'lucide-react'
import { cn } from '@/lib/utils'

const navItems = [
  { href: '/dashboard', label: 'Home', icon: LayoutDashboard },
  { href: '/progress', label: 'Progress', icon: TrendingUp },
  { href: '/log', label: 'Log', icon: PlusCircle, primary: true },
  { href: '/supporter', label: 'Support', icon: Users },
  { href: '/goals', label: 'Goals', icon: Target },
]

export function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bottom-nav">
      <div className="mx-auto max-w-md">
        <div className="bg-card border-t border-border flex items-center justify-around px-2 py-2">
          {navItems.map(({ href, label, icon: Icon, primary }) => {
            const isActive = pathname === href || (href !== '/dashboard' && pathname.startsWith(href))
            return (
              <Link
                key={href}
                href={href}
                className={cn(
                  'flex flex-col items-center gap-1 px-3 py-1 rounded-xl transition-all',
                  primary
                    ? 'relative -top-3 bg-primary text-primary-foreground shadow-lg rounded-2xl px-4 py-3 min-w-[64px]'
                    : isActive
                    ? 'text-primary'
                    : 'text-muted-foreground hover:text-foreground'
                )}
              >
                <Icon className={cn('w-5 h-5', primary && 'w-6 h-6')} />
                <span className={cn('text-[10px] font-medium', primary && 'text-xs')}>{label}</span>
              </Link>
            )
          })}
        </div>
      </div>
    </nav>
  )
}

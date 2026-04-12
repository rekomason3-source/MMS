import { cn } from '@/lib/utils'
import { getStreakEmoji, getStreakLabel } from '@/lib/utils'

interface StreakBadgeProps {
  count: number
  label?: string
  className?: string
  size?: 'sm' | 'md' | 'lg'
}

export function StreakBadge({ count, label, className, size = 'md' }: StreakBadgeProps) {
  const isActive = count > 0
  return (
    <div
      className={cn(
        'flex flex-col items-center gap-0.5',
        !isActive && 'opacity-50',
        className
      )}
    >
      <div
        className={cn(
          'rounded-2xl flex items-center gap-1.5 font-semibold',
          isActive ? 'bg-closer-gold/15 text-closer-gold' : 'bg-muted text-muted-foreground',
          size === 'sm' && 'px-2.5 py-1 text-xs',
          size === 'md' && 'px-3 py-1.5 text-sm',
          size === 'lg' && 'px-4 py-2 text-base',
        )}
      >
        <span className={count >= 7 ? 'streak-fire' : ''}>{getStreakEmoji(count)}</span>
        <span>{count}</span>
      </div>
      {label && <span className="text-[10px] text-muted-foreground text-center">{label}</span>}
    </div>
  )
}

import { cn } from '@/lib/utils'
import { Progress } from '@/components/ui/progress'

interface StatCardProps {
  label: string
  value: string
  target?: string
  percent?: number
  icon?: string
  accentColor?: string
  indicatorColor?: string
  className?: string
}

export function StatCard({
  label,
  value,
  target,
  percent,
  icon,
  accentColor = 'bg-closer-sage/10',
  indicatorColor = 'bg-closer-sage',
  className,
}: StatCardProps) {
  return (
    <div className={cn('bg-card rounded-2xl p-4 border border-border', className)}>
      <div className="flex items-center gap-2 mb-2">
        {icon && <span className="text-lg">{icon}</span>}
        <span className="text-xs font-medium text-muted-foreground uppercase tracking-wide">{label}</span>
      </div>
      <div className="flex items-end gap-1 mb-2">
        <span className="text-2xl font-bold text-foreground">{value}</span>
        {target && <span className="text-sm text-muted-foreground pb-0.5">/ {target}</span>}
      </div>
      {percent !== undefined && (
        <Progress value={percent} className="h-1.5" indicatorClassName={indicatorColor} />
      )}
    </div>
  )
}

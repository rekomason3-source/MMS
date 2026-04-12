'use client'

import { cn } from '@/lib/utils'

interface MacroRingProps {
  calories: number
  calorieTarget: number
  protein: number
  proteinTarget: number
  size?: number
  className?: string
}

export function MacroRing({
  calories,
  calorieTarget,
  protein,
  proteinTarget,
  size = 120,
  className,
}: MacroRingProps) {
  const calPercent = Math.min((calories / calorieTarget) * 100, 100)
  const proteinPercent = Math.min((protein / proteinTarget) * 100, 100)

  const outerRadius = (size / 2) - 8
  const innerRadius = (size / 2) - 20
  const outerCircumference = 2 * Math.PI * outerRadius
  const innerCircumference = 2 * Math.PI * innerRadius

  const outerDash = (calPercent / 100) * outerCircumference
  const innerDash = (proteinPercent / 100) * innerCircumference

  return (
    <div className={cn('relative flex items-center justify-center', className)}>
      <svg
        width={size}
        height={size}
        className="progress-ring"
        viewBox={`0 0 ${size} ${size}`}
      >
        {/* Outer ring background (calories) */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={outerRadius}
          fill="none"
          stroke="hsl(var(--muted))"
          strokeWidth="8"
        />
        {/* Outer ring progress (calories) */}
        <circle
          className="progress-ring__circle"
          cx={size / 2}
          cy={size / 2}
          r={outerRadius}
          fill="none"
          stroke="#6B8F71"
          strokeWidth="8"
          strokeDasharray={`${outerDash} ${outerCircumference - outerDash}`}
          strokeLinecap="round"
        />
        {/* Inner ring background (protein) */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={innerRadius}
          fill="none"
          stroke="hsl(var(--muted))"
          strokeWidth="7"
        />
        {/* Inner ring progress (protein) */}
        <circle
          className="progress-ring__circle"
          cx={size / 2}
          cy={size / 2}
          r={innerRadius}
          fill="none"
          stroke="#4A9B8E"
          strokeWidth="7"
          strokeDasharray={`${innerDash} ${innerCircumference - innerDash}`}
          strokeLinecap="round"
        />
      </svg>
      {/* Center text */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-lg font-bold text-foreground">{Math.round(calories)}</span>
        <span className="text-[10px] text-muted-foreground">cal</span>
      </div>
    </div>
  )
}

'use client'

import { useState, useEffect } from 'react'
import { getRandomAffirmation } from '@/lib/encouragement'
import { cn } from '@/lib/utils'
import { Sparkles } from 'lucide-react'

interface EncouragementBannerProps {
  message?: string
  className?: string
  variant?: 'subtle' | 'card'
}

export function EncouragementBanner({
  message,
  className,
  variant = 'subtle',
}: EncouragementBannerProps) {
  const [text, setText] = useState(message || '')

  useEffect(() => {
    if (!message) {
      setText(getRandomAffirmation())
    }
  }, [message])

  if (!text) return null

  if (variant === 'card') {
    return (
      <div className={cn('bg-closer-sage/10 border border-closer-sage/20 rounded-2xl p-4', className)}>
        <div className="flex items-start gap-3">
          <Sparkles className="w-4 h-4 text-closer-sage mt-0.5 flex-shrink-0" />
          <p className="text-sm text-foreground/80 italic leading-relaxed">"{text}"</p>
        </div>
      </div>
    )
  }

  return (
    <div className={cn('flex items-center gap-2 py-2', className)}>
      <Sparkles className="w-3.5 h-3.5 text-closer-sage flex-shrink-0" />
      <p className="text-xs text-muted-foreground italic">{text}</p>
    </div>
  )
}

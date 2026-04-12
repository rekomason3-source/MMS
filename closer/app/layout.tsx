import type { Metadata, Viewport } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Closer — Progress without pressure',
  description:
    'A private accountability app for people who want to reach their health goals with support, not judgment.',
  keywords: ['health', 'accountability', 'nutrition', 'fitness', 'wellness', 'weight loss'],
  authors: [{ name: 'Closer' }],
  openGraph: {
    title: 'Closer',
    description: 'Progress without pressure. Support without shame.',
    type: 'website',
  },
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  themeColor: '#6B8F71',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}>{children}</body>
    </html>
  )
}

import { BottomNav } from '@/components/shared/bottom-nav'
export default function ProgressLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app-container">
      <main className="pb-24 px-4 pt-5">{children}</main>
      <BottomNav />
    </div>
  )
}

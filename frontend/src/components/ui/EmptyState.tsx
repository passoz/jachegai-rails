import type { ReactNode } from 'react'

interface EmptyStateProps {
  title: string
  description?: string
  action?: ReactNode
}

export default function EmptyState({ title, description, action }: EmptyStateProps) {
  return (
    <div className="border-4 border-brutal-black rounded-[1.5rem] bg-brutal-gray p-10 text-center">
      <div className="text-5xl mb-3" aria-hidden="true">
        📦
      </div>
      <h3 className="font-black italic text-2xl text-brutal-black mb-2">{title}</h3>
      {description && <p className="text-black/60 mb-4">{description}</p>}
      {action && <div className="flex justify-center">{action}</div>}
    </div>
  )
}

import { useEffect, type ReactNode } from 'react'

interface ModalProps {
  open: boolean
  onClose: () => void
  title: string
  children: ReactNode
}

export default function Modal({ open, onClose, title, children }: ModalProps) {
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [open, onClose])

  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-label={title}
    >
      <div
        className="w-full max-w-lg border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white p-6"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between mb-4">
          <h2 className="font-black italic text-2xl text-brutal-black">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Fechar"
            className="border-2 border-brutal-black rounded-full w-9 h-9 font-black text-lg leading-none cursor-pointer hover:bg-brutal-red transition-colors"
          >
            ×
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}

import { useEffect } from 'react'

interface ToastProps {
  open: boolean
  type?: 'success' | 'error' | 'info'
  message: string
  onClose: () => void
  durationMs?: number
}

export default function Toast({
  open,
  type = 'success',
  message,
  onClose,
  durationMs = 4000,
}: ToastProps) {
  useEffect(() => {
    if (!open) return
    const timer = setTimeout(() => {
      onClose()
    }, durationMs)
    return () => clearTimeout(timer)
  }, [open, durationMs, onClose])

  if (!open) return null

  const isSuccess = type === 'success'

  return (
    <div
      role="status"
      className={`fixed bottom-6 right-6 z-50 flex items-center justify-between gap-4 max-w-md border-4 border-brutal-black rounded-[1.5rem] p-4 font-bold shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] ${
        isSuccess ? 'bg-white text-brutal-black' : 'bg-brutal-red text-brutal-black'
      }`}
    >
      <div className="flex items-center gap-2">
        <span className="text-xl" aria-hidden="true">
          {isSuccess ? '✅' : '⚠️'}
        </span>
        <p className="text-base">{message}</p>
      </div>

      <button
        type="button"
        onClick={onClose}
        aria-label="Fechar notificação"
        className="text-lg font-black hover:opacity-75 cursor-pointer px-2"
      >
        ✕
      </button>
    </div>
  )
}

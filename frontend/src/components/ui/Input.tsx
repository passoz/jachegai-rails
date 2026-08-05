import type { InputHTMLAttributes } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  hint?: string
}

export default function Input({ label, error, hint, className = '', id, ...rest }: InputProps) {
  const generatedId = label ? label.toLowerCase().replace(/[^a-z0-9]/g, '-') : undefined
  const inputId = id ?? rest.name ?? generatedId

  return (
    <div className="w-full">
      {label && (
        <label htmlFor={inputId} className="block font-bold text-sm uppercase tracking-wider mb-1.5 text-brutal-black">
          {label}
        </label>
      )}
      <input
        id={inputId}
        className={[
          'w-full border-4 border-brutal-black rounded-[1.5rem] px-5 py-3 text-lg',
          'bg-white text-brutal-black placeholder:text-black/40',
          'focus:outline-none focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] focus:-translate-x-0.5 focus:-translate-y-0.5',
          'transition-all duration-150',
          error ? 'border-brutal-red bg-red-50' : '',
          className,
        ].join(' ')}
        {...rest}
      />
      {hint && !error && <p className="mt-1 text-sm font-bold text-black/50">{hint}</p>}
      {error && <p className="mt-1 text-sm font-bold text-brutal-red">{error}</p>}
    </div>
  )
}

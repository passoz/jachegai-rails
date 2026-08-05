import type { ButtonHTMLAttributes, ReactNode } from 'react'

type Variant = 'primary' | 'danger' | 'outline'
type Size = 'sm' | 'md' | 'lg'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: Size
  loading?: boolean
  children: ReactNode
}

const variantClasses: Record<Variant, string> = {
  primary: 'bg-brutal-black text-white hover:bg-brutal-red hover:text-brutal-black',
  danger: 'bg-brutal-red text-brutal-black hover:bg-brutal-black hover:text-white',
  outline: 'bg-white text-brutal-black hover:bg-brutal-gray',
}

const sizeClasses: Record<Size, string> = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-6 py-3 text-base',
  lg: 'px-8 py-4 text-lg',
}

export default function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled,
  children,
  className = '',
  ...rest
}: ButtonProps) {
  return (
    <button
      type="button"
      disabled={disabled || loading}
      className={[
        'border-4 border-brutal-black rounded-[1.5rem]',
        'shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]',
        'font-black italic tracking-wide',
        'transition-all duration-150',
        'hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5',
        'disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]',
        'cursor-pointer',
        variantClasses[variant],
        sizeClasses[size],
        className,
      ].join(' ')}
      {...rest}
    >
      {loading ? '...' : children}
    </button>
  )
}

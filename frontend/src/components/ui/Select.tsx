interface Option {
  value: string
  label: string
}

interface SelectProps {
  label?: string
  name?: string
  options: Option[]
  value?: string
  onChange?: (value: string) => void
  error?: string
  placeholder?: string
  disabled?: boolean
}

export default function Select({
  label,
  name,
  options,
  value,
  onChange,
  error,
  placeholder,
  disabled,
}: SelectProps) {
  return (
    <div className="w-full">
      {label && (
        <label htmlFor={name} className="block font-bold text-sm uppercase tracking-wider mb-1.5 text-brutal-black">
          {label}
        </label>
      )}
      <select
        id={name}
        name={name}
        value={value}
        disabled={disabled}
        onChange={(e) => onChange?.(e.target.value)}
        className={[
          'w-full border-4 border-brutal-black rounded-[1.5rem] px-5 py-3 text-lg',
          'bg-white text-brutal-black',
          'focus:outline-none focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]',
          'transition-all duration-150',
          'disabled:opacity-50 disabled:cursor-not-allowed',
          error ? 'border-brutal-red' : '',
        ].join(' ')}
      >
        {placeholder && <option value="">{placeholder}</option>}
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
      {error && <p className="mt-1 text-sm font-bold text-brutal-red">{error}</p>}
    </div>
  )
}

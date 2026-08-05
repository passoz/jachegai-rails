interface PageTitleProps {
  title: string
  subtitle?: string
}

export default function PageTitle({ title, subtitle }: PageTitleProps) {
  return (
    <div className="mb-8">
      <h1 className="text-4xl font-black italic text-brutal-black">{title}</h1>
      {subtitle && <p className="mt-1 text-lg text-black/60">{subtitle}</p>}
    </div>
  )
}

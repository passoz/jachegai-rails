export default function LoadingSpinner({ label = 'Carregando...' }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-10 gap-3">
      <div
        className="w-10 h-10 border-4 border-brutal-black border-t-transparent rounded-md animate-spin"
        aria-hidden="true"
      />
      <p className="font-bold text-sm text-black/60 uppercase tracking-wider">{label}</p>
    </div>
  )
}

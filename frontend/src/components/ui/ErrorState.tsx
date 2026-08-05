import Button from './Button'

interface ErrorStateProps {
  title?: string
  message?: string
  onRetry?: () => void
}

export default function ErrorState({
  title = 'Ops, algo deu errado.',
  message = 'Não foi possível carregar os dados. Tente novamente.',
  onRetry,
}: ErrorStateProps) {
  return (
    <div className="border-4 border-brutal-black rounded-[1.5rem] bg-brutal-red/20 p-10 text-center">
      <div className="text-5xl mb-3" aria-hidden="true">
        ⚠️
      </div>
      <h3 className="font-black italic text-2xl text-brutal-black mb-2">{title}</h3>
      <p className="text-black/70 mb-5">{message}</p>
      {onRetry && (
        <div className="flex justify-center">
          <Button variant="danger" onClick={onRetry}>
            Tentar novamente
          </Button>
        </div>
      )}
    </div>
  )
}

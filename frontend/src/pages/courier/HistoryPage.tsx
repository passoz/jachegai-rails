import { useEffect, useState } from 'react'
import { getDeliveryHistory } from '../../services/courierDeliveries'
import type { CourierOrder } from '../../services/courierDeliveries'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'

export default function HistoryPage() {
  const [history, setHistory] = useState<CourierOrder[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    getDeliveryHistory()
      .then(setHistory)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  return (
    <div>
      <PageTitle title="Histórico de Entregas" subtitle="Veja todas as suas corridas concluídas" />

      {error && (
        <ErrorState
          title="Erro ao carregar histórico"
          message="Não foi possível exibir seu histórico de entregas."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando histórico..." />}

      {!loading && !error && history && history.length === 0 && (
        <EmptyState
          title="Nenhuma entrega no histórico"
          description="Você ainda não concluiu nenhuma corrida de entrega."
        />
      )}

      {!loading && !error && history && history.length > 0 && (
        <div className="space-y-4 max-w-4xl">
          {history.map((o) => (
            <div
              key={o.id}
              className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex flex-wrap items-center justify-between gap-4"
            >
              <div>
                <div className="flex items-center gap-3 mb-1">
                  <span className="font-mono text-sm font-bold text-black/40">#{o.id.slice(0, 8)}</span>
                  <Badge status={o.order_state} />
                </div>
                <h4 className="font-black italic text-xl text-brutal-black">
                  {o.seller_name ?? 'Restaurante'}
                </h4>
                {o.created_at && (
                  <p className="text-xs font-bold text-black/40 mt-1">
                    Concluído em {new Date(o.created_at).toLocaleDateString('pt-BR')}
                  </p>
                )}
              </div>

              <div className="text-right">
                <p className="text-xs font-bold text-black/50 uppercase">Ganho da corrida</p>
                <p className="font-black italic text-2xl text-brutal-red">
                  {formatMoney(o.courier_fee_cents, o.currency)}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

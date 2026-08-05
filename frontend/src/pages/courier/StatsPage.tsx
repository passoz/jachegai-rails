import { useEffect, useState } from 'react'
import { getCourierStats } from '../../services/courierDeliveries'
import type { CourierStats } from '../../services/courierDeliveries'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function StatsPage() {
  const [stats, setStats] = useState<CourierStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    getCourierStats()
      .then(setStats)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const averageCents =
    stats && stats.total_deliveries > 0
      ? Math.round(stats.total_earnings_cents / stats.total_deliveries)
      : 0

  return (
    <div>
      <PageTitle title="Estatísticas e Ganhos" subtitle="Resumo do seu desempenho e faturamento" />

      {error && (
        <ErrorState
          title="Erro ao carregar estatísticas"
          message="Não foi possível buscar os dados de faturamento."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando métricas..." />}

      {!loading && !error && stats && (
        <div className="grid md:grid-cols-3 gap-6 max-w-4xl">
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">
              Entregas Realizadas
            </p>
            <p className="font-black italic text-5xl text-brutal-black">{stats.total_deliveries}</p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">
              Ganhos Totais
            </p>
            <p className="font-black italic text-4xl text-brutal-red">
              {formatMoney(stats.total_earnings_cents, stats.currency)}
            </p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">
              Média por Entrega
            </p>
            <p className="font-black italic text-4xl text-brutal-black">
              {formatMoney(averageCents, stats.currency)}
            </p>
          </div>
        </div>
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { getAdminDashboard } from '../../services/admin'
import type { AdminDashboardMetrics } from '../../services/admin'
import PageTitle from '../../components/ui/PageTitle'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function DashboardPage() {
  const [metrics, setMetrics] = useState<AdminDashboardMetrics | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminDashboard()
      .then(setMetrics)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  return (
    <div>
      <PageTitle title="Dashboard do Administrador" subtitle="Visão geral do sistema e métricas em tempo real" />

      {error && (
        <ErrorState
          title="Erro ao carregar dashboard"
          message="Não foi possível buscar as métricas do sistema."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando métricas..." />}

      {!loading && !error && metrics && (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl">
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-1">👥 Total de Usuários</p>
            <p className="font-black italic text-5xl text-brutal-black">{metrics.users_count}</p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-1">🏪 Sellers Ativos</p>
            <p className="font-black italic text-5xl text-brutal-black">{metrics.active_sellers_count}</p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-1">🛵 Couriers Ativos</p>
            <p className="font-black italic text-5xl text-brutal-black">{metrics.active_couriers_count}</p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-1">📦 Pedidos Hoje</p>
            <p className="font-black italic text-5xl text-brutal-red">{metrics.orders_today_count}</p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-1">🎫 Tickets Abertos</p>
            <p className="font-black italic text-5xl text-brutal-black">{metrics.open_tickets_count}</p>
          </div>

          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-1">💳 Pagamentos Pendentes</p>
            <p className="font-black italic text-5xl text-brutal-red">{metrics.pending_payments_count}</p>
          </div>
        </div>
      )}
    </div>
  )
}

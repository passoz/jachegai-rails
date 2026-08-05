import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listSellerOrders } from '../../services/sellerOrders'
import type { SellerOrder } from '../../services/sellerOrders'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'

type StatusFilter = 'all' | 'pending' | 'accepted' | 'preparing' | 'ready'

export default function OrdersPage() {
  const [orders, setOrders] = useState<SellerOrder[] | null>(null)
  const [filter, setFilter] = useState<StatusFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = (status: StatusFilter) => {
    setLoading(true)
    setError(false)
    const params = status === 'all' ? {} : { status }
    listSellerOrders(params)
      .then(setOrders)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load(filter)
  }, [filter])

  const pendingCount = orders?.filter((o) => o.status === 'pending').length ?? 0

  return (
    <div>
      <PageTitle title="Pedidos recebidos" subtitle="Gerencie os pedidos dos clientes da sua loja" />

      {/* Tabs de Filtro */}
      <div className="flex items-center gap-2 overflow-x-auto pb-4 mb-6">
        {[
          { id: 'all', label: 'Todos' },
          { id: 'pending', label: 'Pendentes', badge: pendingCount > 0 },
          { id: 'accepted', label: 'Aceitos' },
          { id: 'preparing', label: 'Em preparação' },
          { id: 'ready', label: 'Prontos' },
        ].map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setFilter(tab.id as StatusFilter)}
            className={`px-4 py-2 border-4 border-brutal-black rounded-[1.5rem] font-bold text-sm transition-all relative ${
              filter === tab.id
                ? 'bg-brutal-black text-white'
                : 'bg-white text-brutal-black hover:bg-brutal-gray'
            }`}
          >
            {tab.label}
            {tab.badge && (
              <span className="ml-2 inline-block w-3 h-3 bg-brutal-red rounded-full animate-ping" />
            )}
          </button>
        ))}
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar pedidos"
          message="Não foi possível exibir a lista de pedidos da loja."
          onRetry={() => load(filter)}
        />
      )}

      {loading && <LoadingSpinner label="Carregando pedidos..." />}

      {!loading && !error && orders && orders.length === 0 && (
        <EmptyState
          title="Nenhum pedido encontrado"
          description="Não há pedidos na categoria selecionada."
        />
      )}

      {!loading && !error && orders && orders.length > 0 && (
        <div className="space-y-4 max-w-4xl">
          {orders.map((o) => (
            <Link
              key={o.id}
              to={`/seller/orders/${o.id}`}
              className="block border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5 transition-all"
            >
              <div className="flex items-start justify-between flex-wrap gap-4">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <span className="font-mono text-sm font-bold text-black/50">#{o.id.slice(0, 8)}</span>
                    <Badge status={o.status} />
                  </div>
                  <h3 className="font-black italic text-xl text-brutal-black">
                    {o.customer_name ?? 'Cliente'}
                  </h3>
                  <p className="text-sm font-bold text-black/60 mt-1">
                    {o.items.map((i) => `${i.quantity}x ${i.name}`).join(', ')}
                  </p>
                </div>

                <div className="text-right">
                  <p className="font-black italic text-2xl text-brutal-red">
                    {formatMoney(o.total_cents, o.currency)}
                  </p>
                  <p className="text-xs font-bold text-black/40 mt-1">
                    {new Date(o.created_at).toLocaleTimeString('pt-BR')}
                  </p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

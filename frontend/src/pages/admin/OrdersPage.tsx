import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminOrders } from '../../services/adminOps'
import type { SellerOrder } from '../../services/sellerOrders'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

type StatusFilter = 'all' | 'pending' | 'accepted' | 'preparing' | 'ready' | 'delivered' | 'cancelled'

export default function OrdersPage() {
  const [orders, setOrders] = useState<SellerOrder[] | null>(null)
  const [filter, setFilter] = useState<StatusFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = (status: StatusFilter) => {
    setLoading(true)
    setError(false)
    const params = status === 'all' ? {} : { status }
    listAdminOrders(params)
      .then(setOrders)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load(filter)
  }, [filter])

  const tableColumns = [
    {
      key: 'id',
      header: 'Pedido (ID)',
      render: (o: SellerOrder) => (
        <Link to={`/admin/orders/${o.id}`} className="font-mono text-sm font-bold text-brutal-black hover:underline">
          #{o.id.slice(0, 8)}
        </Link>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (o: SellerOrder) => <Badge status={o.status} />,
    },
    {
      key: 'total',
      header: 'Total',
      render: (o: SellerOrder) => (
        <span className="font-black italic text-brutal-red">
          {formatMoney(o.total_cents, o.currency)}
        </span>
      ),
    },
    {
      key: 'date',
      header: 'Data',
      render: (o: SellerOrder) => (
        <span className="text-xs font-bold text-black/60">
          {new Date(o.created_at).toLocaleString('pt-BR')}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (o: SellerOrder) => (
        <Link to={`/admin/orders/${o.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Detalhes →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Gestão de Pedidos (Oversight)" subtitle="Acompanhe todos os pedidos da plataforma" />

      {/* Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-4 mb-6">
        {[
          { id: 'all', label: 'Todos' },
          { id: 'pending', label: 'Pendentes' },
          { id: 'accepted', label: 'Aceitos' },
          { id: 'ready', label: 'Prontos' },
          { id: 'delivered', label: 'Entregues' },
          { id: 'cancelled', label: 'Cancelados' },
        ].map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setFilter(tab.id as StatusFilter)}
            className={`px-4 py-2 border-4 border-brutal-black rounded-[1.5rem] font-bold text-sm transition-all ${
              filter === tab.id
                ? 'bg-brutal-black text-white'
                : 'bg-white text-brutal-black hover:bg-brutal-gray'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar pedidos"
          message="Não foi possível buscar a lista de pedidos."
          onRetry={() => load(filter)}
        />
      )}

      {loading && <LoadingSpinner label="Carregando pedidos..." />}

      {!loading && !error && orders && (
        <Table columns={tableColumns} data={orders} emptyMessage="Nenhum pedido encontrado nesta categoria." />
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminPayments } from '../../services/adminOps'
import type { AdminPayment } from '../../services/adminOps'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function PaymentsPage() {
  const [payments, setPayments] = useState<AdminPayment[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    listAdminPayments()
      .then(setPayments)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const tableColumns = [
    {
      key: 'id',
      header: 'ID do Pagamento',
      render: (p: AdminPayment) => (
        <Link to={`/admin/payments/${p.id}`} className="font-mono text-sm font-bold text-brutal-black hover:underline">
          #{p.id.slice(0, 8)}
        </Link>
      ),
    },
    {
      key: 'order_id',
      header: 'Pedido Vinculado',
      render: (p: AdminPayment) => (
        <Link to={`/admin/orders/${p.order_id}`} className="font-mono text-sm text-black/60 hover:underline">
          #{p.order_id.slice(0, 8)}
        </Link>
      ),
    },
    {
      key: 'amount',
      header: 'Valor',
      render: (p: AdminPayment) => (
        <span className="font-black italic text-brutal-red">
          {formatMoney(p.amount_cents, p.currency)}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (p: AdminPayment) => <Badge status={p.status} />,
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (p: AdminPayment) => (
        <Link to={`/admin/payments/${p.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Detalhes →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Gestão de Pagamentos" subtitle="Acompanhamento financeiro das transações" />

      {error && (
        <ErrorState
          title="Erro ao carregar pagamentos"
          message="Não foi possível buscar a lista de transações financeiras."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando pagamentos..." />}

      {!loading && !error && payments && (
        <Table columns={tableColumns} data={payments} emptyMessage="Nenhum pagamento registrado." />
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminTickets } from '../../services/adminOps'
import type { CustomerTicket } from '../../services/customerOrders'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

type StatusFilter = 'all' | 'open' | 'in_progress' | 'resolved' | 'closed'

export default function TicketsPage() {
  const [tickets, setTickets] = useState<CustomerTicket[] | null>(null)
  const [filter, setFilter] = useState<StatusFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = (status: StatusFilter) => {
    setLoading(true)
    setError(false)
    const params = status === 'all' ? {} : { status }
    listAdminTickets(params)
      .then(setTickets)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load(filter)
  }, [filter])

  const tableColumns = [
    {
      key: 'subject',
      header: 'Assunto',
      render: (t: CustomerTicket) => (
        <Link to={`/admin/tickets/${t.id}`} className="font-black italic text-lg hover:underline text-brutal-black">
          {t.subject}
        </Link>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (t: CustomerTicket) => <Badge status={t.status} />,
    },
    {
      key: 'date',
      header: 'Data de Abertura',
      render: (t: CustomerTicket) => (
        <span className="text-xs font-bold text-black/60">
          {new Date(t.created_at).toLocaleString('pt-BR')}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (t: CustomerTicket) => (
        <Link to={`/admin/tickets/${t.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Atender →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Atendimento ao Cliente (Tickets)" subtitle="Gerencie e responda os chamados de suporte" />

      {/* Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-4 mb-6">
        {[
          { id: 'all', label: 'Todos' },
          { id: 'open', label: 'Abertos' },
          { id: 'in_progress', label: 'Em atendimento' },
          { id: 'resolved', label: 'Resolvidos' },
          { id: 'closed', label: 'Fechados' },
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
          title="Erro ao carregar tickets"
          message="Não foi possível buscar a lista de chamados de suporte."
          onRetry={() => load(filter)}
        />
      )}

      {loading && <LoadingSpinner label="Carregando tickets..." />}

      {!loading && !error && tickets && (
        <Table columns={tableColumns} data={tickets} emptyMessage="Nenhum ticket encontrado nesta categoria." />
      )}
    </div>
  )
}

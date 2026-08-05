import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminCouriers } from '../../services/adminModeration'
import type { CourierProfile } from '../../services/courier'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

type StatusFilter = 'all' | 'pending_review' | 'approved' | 'suspended' | 'rejected'

export default function CouriersPage() {
  const [couriers, setCouriers] = useState<CourierProfile[] | null>(null)
  const [filter, setFilter] = useState<StatusFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = (status: StatusFilter) => {
    setLoading(true)
    setError(false)
    const params = status === 'all' ? {} : { status }
    listAdminCouriers(params)
      .then(setCouriers)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load(filter)
  }, [filter])

  const tableColumns = [
    {
      key: 'name',
      header: 'Nome do Entregador',
      render: (c: CourierProfile) => (
        <Link to={`/admin/couriers/${c.id}`} className="font-black italic text-lg hover:underline text-brutal-black">
          {c.full_name}
        </Link>
      ),
    },
    { key: 'vehicle', header: 'Veículo', render: (c: CourierProfile) => <span className="capitalize font-bold">{c.vehicle_type}</span> },
    {
      key: 'approval',
      header: 'Aprovação',
      render: (c: CourierProfile) => <Badge status={c.approval_state} />,
    },
    {
      key: 'operational',
      header: 'Operacional',
      render: (c: CourierProfile) => <Badge status={c.operational_state} />,
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (c: CourierProfile) => (
        <Link to={`/admin/couriers/${c.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Moderar →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Moderação de Couriers" subtitle="Analise e gerencie o cadastro de entregadores" />

      {/* Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-4 mb-6">
        {[
          { id: 'all', label: 'Todos' },
          { id: 'pending_review', label: 'Pendentes' },
          { id: 'approved', label: 'Aprovados' },
          { id: 'suspended', label: 'Suspensos' },
          { id: 'rejected', label: 'Rejeitados' },
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
          title="Erro ao carregar entregadores"
          message="Não foi possível buscar a lista de couriers para moderação."
          onRetry={() => load(filter)}
        />
      )}

      {loading && <LoadingSpinner label="Carregando entregadores..." />}

      {!loading && !error && couriers && (
        <Table columns={tableColumns} data={couriers} emptyMessage="Nenhum entregador encontrado nesta categoria." />
      )}
    </div>
  )
}

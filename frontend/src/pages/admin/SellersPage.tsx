import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminSellers } from '../../services/adminModeration'
import type { SellerProfile } from '../../services/seller'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

type StatusFilter = 'all' | 'pending_review' | 'approved' | 'suspended' | 'rejected'

export default function SellersPage() {
  const [sellers, setSellers] = useState<SellerProfile[] | null>(null)
  const [filter, setFilter] = useState<StatusFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = (status: StatusFilter) => {
    setLoading(true)
    setError(false)
    const params = status === 'all' ? {} : { status }
    listAdminSellers(params)
      .then(setSellers)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load(filter)
  }, [filter])

  const tableColumns = [
    {
      key: 'name',
      header: 'Nome da loja',
      render: (s: SellerProfile) => (
        <Link to={`/admin/sellers/${s.id}`} className="font-black italic text-lg hover:underline text-brutal-black">
          {s.name}
        </Link>
      ),
    },
    { key: 'slug', header: 'Slug', render: (s: SellerProfile) => <span className="font-mono text-sm">{s.slug}</span> },
    {
      key: 'status',
      header: 'Moderação',
      render: (s: SellerProfile) => <Badge status={s.moderation_state} />,
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (s: SellerProfile) => (
        <Link to={`/admin/sellers/${s.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Moderar →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Moderação de Sellers" subtitle="Analise e gerencie o cadastro de lojas na plataforma" />

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
          title="Erro ao carregar sellers"
          message="Não foi possível buscar a lista de lojas para moderação."
          onRetry={() => load(filter)}
        />
      )}

      {loading && <LoadingSpinner label="Carregando lojas..." />}

      {!loading && !error && sellers && (
        <Table columns={tableColumns} data={sellers} emptyMessage="Nenhum seller encontrado nesta categoria." />
      )}
    </div>
  )
}

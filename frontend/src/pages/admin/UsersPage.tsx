import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminUsers } from '../../services/admin'
import type { AdminUser } from '../../services/admin'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    listAdminUsers()
      .then(setUsers)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const tableColumns = [
    {
      key: 'name',
      header: 'Nome',
      render: (u: AdminUser) => (
        <Link to={`/admin/users/${u.id}`} className="font-black italic text-lg hover:underline text-brutal-black">
          {u.name}
        </Link>
      ),
    },
    { key: 'email', header: 'E-mail', render: (u: AdminUser) => <span className="font-mono text-sm font-bold">{u.email}</span> },
    {
      key: 'roles',
      header: 'Papéis',
      render: (u: AdminUser) => (
        <div className="flex gap-1 flex-wrap">
          {u.roles.map((r) => (
            <Badge key={r} status={r} label={r} />
          ))}
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (u: AdminUser) => <Badge status={u.active ? 'active' : 'inactive'} label={u.active ? 'Ativo' : 'Inativo'} />,
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (u: AdminUser) => (
        <Link to={`/admin/users/${u.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Ver detalhes →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Gestão de Usuários" subtitle="Listagem de todos os usuários cadastrados na plataforma" />

      {error && (
        <ErrorState
          title="Erro ao carregar usuários"
          message="Não foi possível exibir a lista de usuários."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando usuários..." />}

      {!loading && !error && users && (
        <Table columns={tableColumns} data={users} emptyMessage="Nenhum usuário encontrado." />
      )}
    </div>
  )
}

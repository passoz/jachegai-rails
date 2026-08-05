import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getAdminUser, disableAdminUser, enableAdminUser } from '../../services/admin'
import type { AdminUser } from '../../services/admin'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'

export default function UserDetailPage() {
  const { id = '' } = useParams()
  const [user, setUser] = useState<AdminUser | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [confirmModalOpen, setConfirmModalOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminUser(id)
      .then(setUser)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleToggleStatus = async () => {
    if (!user) return
    setSubmitting(true)
    setFeedback(null)
    try {
      if (user.active) {
        const updated = await disableAdminUser(id)
        setUser(updated)
        setFeedback('Usuário desabilitado com sucesso.')
      } else {
        const updated = await enableAdminUser(id)
        setUser(updated)
        setFeedback('Usuário habilitado com sucesso.')
      }
      setConfirmModalOpen(false)
    } catch {
      setFeedback('Erro ao alterar status do usuário.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div>
      <Link to="/admin/users" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para lista de usuários
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar usuário"
          message="Não foi possível exibir as informações do usuário."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando usuário..." />}

      {!loading && !error && user && (
        <div className="max-w-2xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="flex items-center justify-between flex-wrap gap-4 border-b-4 border-brutal-black pb-4">
            <div>
              <PageTitle title={user.name} subtitle={user.email} />
              <p className="text-xs font-mono text-black/40">ID: {user.id}</p>
            </div>
            <Badge status={user.active ? 'active' : 'inactive'} label={user.active ? 'Ativo' : 'Inativo'} />
          </div>

          <div className="space-y-4">
            <div>
              <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Papéis (Roles)</p>
              <div className="flex gap-2 flex-wrap">
                {user.roles.map((r) => (
                  <Badge key={r} status={r} label={r} />
                ))}
              </div>
            </div>

            {user.created_at && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Data de Cadastro</p>
                <p className="font-black italic text-lg">{new Date(user.created_at).toLocaleString('pt-BR')}</p>
              </div>
            )}
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          <div className="pt-4 border-t-4 border-brutal-black">
            <Button
              variant={user.active ? 'danger' : 'primary'}
              className="w-full"
              onClick={() => {
                if (user.active) {
                  setConfirmModalOpen(true)
                } else {
                  handleToggleStatus()
                }
              }}
            >
              {user.active ? 'Desabilitar usuário' : 'Habilitar usuário'}
            </Button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmModalOpen}
        title="Desabilitar usuário?"
        message={`Tem certeza que deseja desabilitar a conta de ${user?.name}? Ele não poderá mais fazer login no sistema.`}
        confirmLabel="Desabilitar"
        onConfirm={handleToggleStatus}
        onCancel={() => setConfirmModalOpen(false)}
        loading={submitting}
      />
    </div>
  )
}

import { useEffect, useState } from 'react'
import { getCustomerProfile, updateCustomerProfile } from '../../services/customer'
import type { CustomerProfile } from '../../types/customer'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function ProfilePage() {
  const [profile, setProfile] = useState<CustomerProfile | null>(null)
  const [name, setName] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(false)
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; text: string } | null>(
    null,
  )

  const load = () => {
    setLoading(true)
    setError(false)
    getCustomerProfile()
      .then((data) => {
        setProfile(data)
        setName(data.name)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setFeedback(null)
    try {
      const updated = await updateCustomerProfile(name)
      setProfile(updated)
      setName(updated.name)
      setFeedback({ type: 'success', text: 'Perfil atualizado com sucesso!' })
    } catch {
      setFeedback({ type: 'error', text: 'Não foi possível atualizar o perfil.' })
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <PageTitle title="Meu perfil" subtitle="Gerencie suas informações pessoais" />

      {error && (
        <ErrorState
          title="Erro ao carregar perfil"
          message="Não foi possível carregar suas informações."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando perfil..." />}

      {!loading && !error && profile && (
        <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
          <form id="profile-form" onSubmit={handleSubmit} className="space-y-6">
            <Input
              label="Nome completo"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />

            <Input
              label="E-mail"
              type="email"
              value={profile.email}
              disabled
              hint="O e-mail não pode ser alterado."
            />

            {profile.created_at && (
              <div>
                <p className="text-sm font-bold text-black/50">Cliente desde</p>
                <p className="font-black italic text-lg text-brutal-black">
                  {new Date(profile.created_at).toLocaleDateString('pt-BR')}
                </p>
              </div>
            )}

            {feedback && (
              <div
                className={`p-4 border-4 border-brutal-black rounded-[1.5rem] font-bold ${
                  feedback.type === 'success'
                    ? 'bg-emerald-100 text-emerald-900'
                    : 'bg-brutal-red text-white'
                }`}
                role="status"
              >
                {feedback.text}
              </div>
            )}

            <Button type="submit" variant="primary" loading={saving} className="w-full">
              Salvar alterações
            </Button>
          </form>
        </div>
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { getSellerProfile, updateSellerProfile } from '../../services/seller'
import type { SellerProfile, SellerOnboardingPayload } from '../../services/seller'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function ProfilePage() {
  const [profile, setProfile] = useState<SellerProfile | null>(null)
  const [form, setForm] = useState<SellerOnboardingPayload>({ name: '' })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [saving, setSaving] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getSellerProfile()
      .then((data) => {
        setProfile(data)
        setForm({
          name: data.name,
          description: data.description ?? '',
          contact_phone: data.contact_phone ?? '',
          address_city: data.address_city ?? '',
          address_state: data.address_state ?? '',
        })
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
      const updated = await updateSellerProfile(form)
      setProfile(updated)
      setFeedback('Perfil da loja atualizado com sucesso!')
    } catch {
      setFeedback('Erro ao atualizar perfil da loja.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <PageTitle title="Perfil da loja" subtitle="Gerencie as informações públicas e contato do seu negócio" />

      {error && (
        <ErrorState
          title="Erro ao carregar perfil"
          message="Não foi possível carregar as informações da loja."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando perfil da loja..." />}

      {!loading && !error && profile && (
        <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="flex items-center justify-between gap-4 border-b-4 border-brutal-black pb-4">
            <div>
              <p className="text-sm font-bold text-black/50">Status de moderação</p>
              <p className="font-mono text-xs text-black/40 mt-0.5">Slug: {profile.slug}</p>
            </div>
            <Badge status={profile.moderation_state} />
          </div>

          {profile.moderation_state !== 'approved' && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              Sua loja não está ativa no momento (Status: {profile.moderation_state}).
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              label="Nome da loja"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
            />

            <div className="w-full">
              <label htmlFor="seller-desc" className="block font-bold text-sm uppercase tracking-wider mb-1.5 text-brutal-black">
                Descrição da loja
              </label>
              <textarea
                id="seller-desc"
                rows={3}
                className="w-full border-4 border-brutal-black rounded-[1.5rem] px-5 py-3 text-lg bg-white text-brutal-black placeholder:text-black/40 focus:outline-none focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
                value={form.description ?? ''}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </div>

            <Input
              label="Telefone de contato"
              value={form.contact_phone ?? ''}
              onChange={(e) => setForm({ ...form, contact_phone: e.target.value })}
            />

            <div className="grid grid-cols-3 gap-3">
              <div className="col-span-2">
                <Input
                  label="Cidade"
                  value={form.address_city ?? ''}
                  onChange={(e) => setForm({ ...form, address_city: e.target.value })}
                />
              </div>
              <div>
                <Input
                  label="Estado (UF)"
                  value={form.address_state ?? ''}
                  onChange={(e) => setForm({ ...form, address_state: e.target.value })}
                />
              </div>
            </div>

            {feedback && (
              <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
                {feedback}
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

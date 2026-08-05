import { useEffect, useState } from 'react'
import { getSellerSettings, updateSellerSettings } from '../../services/seller'
import type { SellerSettings } from '../../services/seller'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function SettingsPage() {
  const [settings, setSettings] = useState<SellerSettings | null>(null)
  const [email, setEmail] = useState('')
  const [autoAccept, setAutoAccept] = useState(false)

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [saving, setSaving] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getSellerSettings()
      .then((data) => {
        setSettings(data)
        setEmail(data.notification_email ?? '')
        setAutoAccept(Boolean(data.auto_accept_orders))
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
      const updated = await updateSellerSettings({
        notification_email: email,
        auto_accept_orders: autoAccept,
      })
      setSettings(updated)
      setFeedback('Configurações salvas com sucesso!')
    } catch {
      setFeedback('Erro ao salvar configurações.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <PageTitle title="Configurações da loja" subtitle="Ajustes operacionais e de notificações" />

      {error && (
        <ErrorState
          title="Erro ao carregar configurações"
          message="Não foi possível exibir as configurações."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando configurações..." />}

      {!loading && !error && settings && (
        <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
          <form onSubmit={handleSubmit} className="space-y-6">
            <Input
              label="E-mail para notificações de novos pedidos"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />

            <div className="flex items-center gap-3 p-4 border-4 border-brutal-black rounded-[1.5rem] bg-brutal-gray">
              <input
                id="auto-accept"
                type="checkbox"
                checked={autoAccept}
                onChange={(e) => setAutoAccept(e.target.checked)}
                className="w-6 h-6 border-2 border-brutal-black rounded accent-brutal-red cursor-pointer"
              />
              <label htmlFor="auto-accept" className="font-bold text-sm uppercase tracking-wide cursor-pointer text-brutal-black">
                Aceitar pedidos automaticamente
              </label>
            </div>

            {feedback && (
              <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
                {feedback}
              </div>
            )}

            <Button type="submit" variant="primary" loading={saving} className="w-full">
              Salvar configurações
            </Button>
          </form>
        </div>
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { getCourierProfile, updateCourierProfile } from '../../services/courier'
import type { CourierProfile, CourierOnboardingPayload } from '../../services/courier'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

const vehicleOptions = [
  { value: 'moto', label: 'Moto' },
  { value: 'bicicleta', label: 'Bicicleta' },
  { value: 'carro', label: 'Carro' },
]

export default function ProfilePage() {
  const [profile, setProfile] = useState<CourierProfile | null>(null)
  const [form, setForm] = useState<CourierOnboardingPayload>({
    full_name: '',
    vehicle_type: 'moto',
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [saving, setSaving] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getCourierProfile()
      .then((data) => {
        setProfile(data)
        setForm({
          full_name: data.full_name,
          document: data.document ?? '',
          vehicle_type: data.vehicle_type ?? 'moto',
          phone: data.phone ?? '',
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
      const updated = await updateCourierProfile(form)
      setProfile(updated)
      setFeedback('Perfil atualizado com sucesso!')
    } catch {
      setFeedback('Erro ao atualizar perfil.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <PageTitle title="Perfil do Entregador" subtitle="Gerencie seus dados de cadastro e veículo" />

      {error && (
        <ErrorState
          title="Erro ao carregar perfil"
          message="Não foi possível exibir seus dados de entregador."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando perfil..." />}

      {!loading && !error && profile && (
        <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="flex items-center justify-between gap-4 border-b-4 border-brutal-black pb-4 flex-wrap">
            <div>
              <p className="text-sm font-bold text-black/50">Status de Aprovação</p>
              <div className="mt-1">
                <Badge status={profile.approval_state} />
              </div>
            </div>

            <div>
              <p className="text-sm font-bold text-black/50">Status Operacional</p>
              <div className="mt-1">
                <Badge status={profile.operational_state} />
              </div>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              label="Nome completo"
              value={form.full_name}
              onChange={(e) => setForm({ ...form, full_name: e.target.value })}
              required
            />

            <Input
              label="CPF / Documento (Readonly)"
              value={profile.document ?? '—'}
              disabled
            />

            <Select
              label="Tipo de Veículo"
              options={vehicleOptions}
              value={form.vehicle_type}
              onChange={(val) => setForm({ ...form, vehicle_type: val })}
            />

            <Input
              label="Telefone de contato"
              value={form.phone ?? ''}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />

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

import { useEffect, useState } from 'react'
import { submitCourierOnboarding, getCourierProfile } from '../../services/courier'
import type { CourierOnboardingPayload, CourierProfile } from '../../services/courier'
import { unwrapError } from '../../services/api'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import Badge from '../../components/ui/Badge'

const vehicleOptions = [
  { value: 'moto', label: 'Moto' },
  { value: 'bicicleta', label: 'Bicicleta' },
  { value: 'carro', label: 'Carro' },
]

export default function OnboardingPage() {
  const [existingProfile, setExistingProfile] = useState<CourierProfile | null>(null)
  const [checking, setChecking] = useState(true)

  const [form, setForm] = useState<CourierOnboardingPayload>({
    full_name: '',
    document: '',
    vehicle_type: 'moto',
    phone: '',
  })
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
  const [submitting, setSubmitting] = useState(false)

  const [createdProfile, setCreatedProfile] = useState<CourierProfile | null>(null)
  const [generalError, setGeneralError] = useState<string | null>(null)

  useEffect(() => {
    getCourierProfile()
      .then((data) => setExistingProfile(data))
      .catch(() => setExistingProfile(null))
      .finally(() => setChecking(false))
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setFieldErrors({})
    setGeneralError(null)

    try {
      const res = await submitCourierOnboarding(form)
      setCreatedProfile(res)
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.context && typeof apiErr.context === 'object') {
        setFieldErrors(apiErr.context as Record<string, string>)
      } else {
        setGeneralError(apiErr.message || 'Falha ao enviar cadastro de entregador.')
      }
    } finally {
      setSubmitting(false)
    }
  }

  if (checking) {
    return <LoadingSpinner label="Verificando cadastro de entregador..." />
  }

  if (existingProfile || createdProfile) {
    const p = existingProfile ?? createdProfile
    return (
      <div className="max-w-xl">
        <PageTitle title="Cadastro de Entregador" subtitle="Status da sua solicitação" />

        <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
          <div className="flex items-center justify-between gap-4">
            <h3 className="font-black italic text-2xl text-brutal-black">{p?.full_name}</h3>
            {p?.approval_state && <Badge status={p.approval_state} />}
          </div>

          <p className="font-bold text-black/70">
            Veículo cadastrado: <span className="capitalize">{p?.vehicle_type}</span>
          </p>

          <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
            Cadastro enviado para análise. Você poderá alterar sua disponibilidade e aceitar entregas assim que for aprovado pela administração.
          </div>
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageTitle title="Cadastro de Entregador" subtitle="Cadastre-se para fazer entregas na plataforma JaChegai" />

      <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Nome completo"
            placeholder="Seu nome completo"
            value={form.full_name}
            onChange={(e) => setForm({ ...form, full_name: e.target.value })}
            error={fieldErrors.full_name}
            required
          />

          <Input
            label="CPF / Documento"
            placeholder="000.000.000-00"
            value={form.document ?? ''}
            onChange={(e) => setForm({ ...form, document: e.target.value })}
            error={fieldErrors.document}
          />

          <Select
            label="Tipo de Veículo"
            options={vehicleOptions}
            value={form.vehicle_type}
            onChange={(val) => setForm({ ...form, vehicle_type: val })}
            error={fieldErrors.vehicle_type}
          />

          <Input
            label="Telefone de contato"
            placeholder="(11) 99999-9999"
            value={form.phone ?? ''}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
            error={fieldErrors.phone}
          />

          {generalError && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-red text-brutal-black font-bold rounded-[1.5rem]" role="alert">
              {generalError}
            </div>
          )}

          <Button type="submit" variant="primary" loading={submitting} className="w-full mt-4">
            Cadastrar como entregador →
          </Button>
        </form>
      </div>
    </div>
  )
}

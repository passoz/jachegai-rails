import { useEffect, useState } from 'react'
import { submitSellerOnboarding, getSellerProfile } from '../../services/seller'
import type { SellerOnboardingPayload, SellerProfile } from '../../services/seller'
import { unwrapError } from '../../services/api'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import Badge from '../../components/ui/Badge'

const emptyForm: SellerOnboardingPayload = {
  name: '',
  description: '',
  contact_phone: '',
  address_city: '',
  address_state: '',
}

export default function OnboardingPage() {
  const [existingProfile, setExistingProfile] = useState<SellerProfile | null>(null)
  const [checking, setChecking] = useState(true)

  const [form, setForm] = useState<SellerOnboardingPayload>(emptyForm)
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
  const [submitting, setSubmitting] = useState(false)

  const [createdProfile, setCreatedProfile] = useState<SellerProfile | null>(null)
  const [generalError, setGeneralError] = useState<string | null>(null)

  useEffect(() => {
    getSellerProfile()
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
      const res = await submitSellerOnboarding(form)
      setCreatedProfile(res)
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.context && typeof apiErr.context === 'object') {
        setFieldErrors(apiErr.context as Record<string, string>)
      } else {
        setGeneralError(apiErr.message || 'Falha ao enviar cadastro de seller.')
      }
    } finally {
      setSubmitting(false)
    }
  }

  if (checking) {
    return <LoadingSpinner label="Verificando cadastro..." />
  }

  if (existingProfile || createdProfile) {
    const p = existingProfile ?? createdProfile
    return (
      <div className="max-w-xl">
        <PageTitle title="Cadastro de Seller" subtitle="Status da sua solicitação de loja" />

        <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
          <div className="flex items-center justify-between gap-4">
            <h3 className="font-black italic text-2xl text-brutal-black">{p?.name}</h3>
            {p?.moderation_state && <Badge status={p.moderation_state} />}
          </div>

          <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
            Sua loja foi enviada para análise. Você poderá gerenciar produtos assim que for aprovada pela equipe de administração.
          </div>
        </div>
      </div>
    )
  }

  return (
    <div>
      <PageTitle title="Cadastro de Seller" subtitle="Cadastre sua loja para começar a vender no JaChegai" />

      <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Nome da loja"
            placeholder="Ex: Padaria Central"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            error={fieldErrors.name}
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
              placeholder="Descreva o que sua loja vende..."
              value={form.description ?? ''}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
          </div>

          <Input
            label="Telefone de contato"
            placeholder="(11) 99999-9999"
            value={form.contact_phone ?? ''}
            onChange={(e) => setForm({ ...form, contact_phone: e.target.value })}
            error={fieldErrors.contact_phone}
          />

          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2">
              <Input
                label="Cidade"
                value={form.address_city ?? ''}
                onChange={(e) => setForm({ ...form, address_city: e.target.value })}
                error={fieldErrors.address_city}
              />
            </div>
            <div>
              <Input
                label="Estado (UF)"
                value={form.address_state ?? ''}
                onChange={(e) => setForm({ ...form, address_state: e.target.value })}
                error={fieldErrors.address_state}
              />
            </div>
          </div>

          {generalError && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-red text-brutal-black font-bold rounded-[1.5rem]" role="alert">
              {generalError}
            </div>
          )}

          <Button type="submit" variant="primary" loading={submitting} className="w-full mt-4">
            Enviar para aprovação →
          </Button>
        </form>
      </div>
    </div>
  )
}

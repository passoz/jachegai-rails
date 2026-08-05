import { useEffect, useState } from 'react'
import { getCourierProfile, updateCourierAvailability } from '../../services/courier'
import type { CourierProfile } from '../../services/courier'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function AvailabilityPage() {
  const [profile, setProfile] = useState<CourierProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [toggling, setToggling] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getCourierProfile()
      .then(setProfile)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleToggle = async () => {
    if (!profile) return
    const nextAvailable = profile.operational_state === 'offline'
    setToggling(true)
    setFeedback(null)
    try {
      const updated = await updateCourierAvailability(nextAvailable)
      setProfile(updated)
      setFeedback(`Disponibilidade alterada para ${updated.operational_state}.`)
    } catch {
      setFeedback('Erro ao alterar disponibilidade.')
    } finally {
      setToggling(false)
    }
  }

  const isApproved = profile?.approval_state === 'approved'
  const isOnDelivery = profile?.operational_state === 'on_delivery'
  const isAvailable = profile?.operational_state === 'available'

  return (
    <div>
      <PageTitle title="Disponibilidade de Entrega" subtitle="Ligue ou desligue seu radar de entregas" />

      {error && (
        <ErrorState
          title="Erro ao carregar perfil"
          message="Não foi possível verificar seu status operacional."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Verificando status operacional..." />}

      {!loading && !error && profile && (
        <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6 text-center">
          <div>
            <p className="text-sm font-bold uppercase tracking-wider text-black/50 mb-2">
              Status operacional atual
            </p>
            <div className="flex justify-center">
              <Badge status={profile.operational_state} />
            </div>
          </div>

          {!isApproved && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              Aguardando aprovação do admin para iniciar entregas.
            </div>
          )}

          {isOnDelivery && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              Finalize sua entrega atual antes de alterar disponibilidade.
            </div>
          )}

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          <div>
            <Button
              variant={isAvailable ? 'danger' : 'primary'}
              size="lg"
              className="w-full text-xl py-6"
              disabled={!isApproved || isOnDelivery}
              loading={toggling}
              onClick={handleToggle}
            >
              {isAvailable ? 'Ficar offline' : 'Ficar disponível'}
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}

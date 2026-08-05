import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  getAdminCourier,
  approveAdminCourier,
  rejectAdminCourier,
  suspendAdminCourier,
  reinstateAdminCourier,
} from '../../services/adminModeration'
import type { CourierProfile } from '../../services/courier'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

type ActionType = 'reject' | 'suspend' | null

export default function CourierDetailPage() {
  const { id = '' } = useParams()
  const [courier, setCourier] = useState<CourierProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [acting, setActing] = useState(false)
  const [activeModal, setActiveModal] = useState<ActionType>(null)
  const [reason, setReason] = useState('')
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminCourier(id)
      .then(setCourier)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleApprove = async () => {
    setActing(true)
    setFeedback(null)
    try {
      const updated = await approveAdminCourier(id)
      setCourier(updated)
      setFeedback('Entregador aprovado com sucesso!')
    } catch {
      setFeedback('Erro ao aprovar entregador.')
    } finally {
      setActing(false)
    }
  }

  const handleReinstate = async () => {
    setActing(true)
    setFeedback(null)
    try {
      const updated = await reinstateAdminCourier(id)
      setCourier(updated)
      setFeedback('Entregador reativado com sucesso!')
    } catch {
      setFeedback('Erro ao reativar entregador.')
    } finally {
      setActing(false)
    }
  }

  const handleConfirmReasonAction = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!reason.trim()) return
    setActing(true)
    setFeedback(null)
    try {
      if (activeModal === 'reject') {
        const updated = await rejectAdminCourier(id, reason.trim())
        setCourier(updated)
        setFeedback('Entregador rejeitado.')
      } else if (activeModal === 'suspend') {
        const updated = await suspendAdminCourier(id, reason.trim())
        setCourier(updated)
        setFeedback('Entregador suspenso.')
      }
      setActiveModal(null)
      setReason('')
    } catch {
      setFeedback('Erro ao executar ação no entregador.')
    } finally {
      setActing(false)
    }
  }

  return (
    <div>
      <Link to="/admin/couriers" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para moderação de couriers
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar entregador"
          message="Não foi possível buscar as informações do entregador."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando dados do entregador..." />}

      {!loading && !error && courier && (
        <div className="max-w-2xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="flex items-center justify-between flex-wrap gap-4 border-b-4 border-brutal-black pb-4">
            <div>
              <PageTitle title={courier.full_name} subtitle={`Veículo: ${courier.vehicle_type}`} />
              <p className="text-xs font-mono text-black/40">ID: {courier.id}</p>
            </div>
            <div className="flex flex-col items-end gap-1">
              <Badge status={courier.approval_state} />
              <Badge status={courier.operational_state} />
            </div>
          </div>

          <div className="space-y-3 font-medium">
            {courier.document && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider">CPF / Documento</p>
                <p className="font-mono text-base">{courier.document}</p>
              </div>
            )}

            {courier.phone && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider">Contato</p>
                <p className="font-bold">{courier.phone}</p>
              </div>
            )}
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          <div className="pt-4 border-t-4 border-brutal-black flex flex-wrap gap-3">
            {courier.approval_state === 'pending_review' && (
              <>
                <Button variant="primary" loading={acting} onClick={handleApprove}>
                  Aprovar entregador
                </Button>
                <Button variant="danger" loading={acting} onClick={() => setActiveModal('reject')}>
                  Rejeitar entregador
                </Button>
              </>
            )}

            {courier.approval_state === 'approved' && (
              <Button variant="danger" loading={acting} onClick={() => setActiveModal('suspend')}>
                Suspender entregador
              </Button>
            )}

            {(courier.approval_state === 'suspended' || courier.approval_state === 'rejected') && (
              <Button variant="primary" loading={acting} onClick={handleReinstate}>
                Reativar entregador
              </Button>
            )}
          </div>
        </div>
      )}

      {/* Modal com motivo para Rejeitar ou Suspender */}
      <Modal
        open={activeModal !== null}
        onClose={() => setActiveModal(null)}
        title={activeModal === 'reject' ? 'Rejeitar entregador?' : 'Suspender entregador?'}
      >
        <form onSubmit={handleConfirmReasonAction} className="space-y-4">
          <Input
            label="Motivo da ação"
            placeholder="Informe a justificativa..."
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            required
          />

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setActiveModal(null)}>
              Cancelar
            </Button>
            <Button variant="danger" type="submit" loading={acting}>
              {activeModal === 'reject' ? 'Rejeitar' : 'Suspender'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

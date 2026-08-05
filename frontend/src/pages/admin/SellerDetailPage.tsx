import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  getAdminSeller,
  approveAdminSeller,
  rejectAdminSeller,
  suspendAdminSeller,
  reinstateAdminSeller,
} from '../../services/adminModeration'
import type { SellerProfile } from '../../services/seller'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

type ActionType = 'reject' | 'suspend' | null

export default function SellerDetailPage() {
  const { id = '' } = useParams()
  const [seller, setSeller] = useState<SellerProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [acting, setActing] = useState(false)
  const [activeModal, setActiveModal] = useState<ActionType>(null)
  const [reason, setReason] = useState('')
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminSeller(id)
      .then(setSeller)
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
      const updated = await approveAdminSeller(id)
      setSeller(updated)
      setFeedback('Loja aprovada com sucesso!')
    } catch {
      setFeedback('Erro ao aprovar loja.')
    } finally {
      setActing(false)
    }
  }

  const handleReinstate = async () => {
    setActing(true)
    setFeedback(null)
    try {
      const updated = await reinstateAdminSeller(id)
      setSeller(updated)
      setFeedback('Loja reativada com sucesso!')
    } catch {
      setFeedback('Erro ao reativar loja.')
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
        const updated = await rejectAdminSeller(id, reason.trim())
        setSeller(updated)
        setFeedback('Loja rejeitada.')
      } else if (activeModal === 'suspend') {
        const updated = await suspendAdminSeller(id, reason.trim())
        setSeller(updated)
        setFeedback('Loja suspensa.')
      }
      setActiveModal(null)
      setReason('')
    } catch {
      setFeedback('Erro ao executar ação na loja.')
    } finally {
      setActing(false)
    }
  }

  return (
    <div>
      <Link to="/admin/sellers" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para moderação de sellers
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar loja"
          message="Não foi possível buscar as informações da loja."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando dados da loja..." />}

      {!loading && !error && seller && (
        <div className="max-w-2xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="flex items-center justify-between flex-wrap gap-4 border-b-4 border-brutal-black pb-4">
            <div>
              <PageTitle title={seller.name} subtitle={`Slug: ${seller.slug}`} />
              <p className="text-xs font-mono text-black/40">ID: {seller.id}</p>
            </div>
            <Badge status={seller.moderation_state} />
          </div>

          <div className="space-y-3 font-medium">
            {seller.description && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider">Descrição</p>
                <p className="text-lg">{seller.description}</p>
              </div>
            )}

            {seller.contact_phone && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider">Contato</p>
                <p className="font-bold">{seller.contact_phone}</p>
              </div>
            )}

            {seller.address_city && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider">Localização</p>
                <p className="font-bold">
                  {seller.address_city} / {seller.address_state}
                </p>
              </div>
            )}
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          <div className="pt-4 border-t-4 border-brutal-black flex flex-wrap gap-3">
            {seller.moderation_state === 'pending_review' && (
              <>
                <Button variant="primary" loading={acting} onClick={handleApprove}>
                  Aprovar loja
                </Button>
                <Button variant="danger" loading={acting} onClick={() => setActiveModal('reject')}>
                  Rejeitar loja
                </Button>
              </>
            )}

            {seller.moderation_state === 'approved' && (
              <Button variant="danger" loading={acting} onClick={() => setActiveModal('suspend')}>
                Suspender loja
              </Button>
            )}

            {(seller.moderation_state === 'suspended' || seller.moderation_state === 'rejected') && (
              <Button variant="primary" loading={acting} onClick={handleReinstate}>
                Reativar loja
              </Button>
            )}
          </div>
        </div>
      )}

      {/* Modal com motivo para Rejeitar ou Suspender */}
      <Modal
        open={activeModal !== null}
        onClose={() => setActiveModal(null)}
        title={activeModal === 'reject' ? 'Rejeitar loja?' : 'Suspender loja?'}
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

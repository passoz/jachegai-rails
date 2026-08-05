import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getCustomerOrderTracking, cancelCustomerOrder } from '../../services/customerOrders'
import type { OrderTracking } from '../../services/customerOrders'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'

export default function TrackingPage() {
  const { id = '' } = useParams()
  const [tracking, setTracking] = useState<OrderTracking | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [cancelModalOpen, setCancelModalOpen] = useState(false)
  const [cancelling, setCancelling] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getCustomerOrderTracking(id)
      .then(setTracking)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleCancel = async () => {
    setCancelling(true)
    try {
      await cancelCustomerOrder(id, 'Cancelado pelo cliente')
      setFeedback('Pedido cancelado com sucesso.')
      setCancelModalOpen(false)
      load()
    } catch {
      setFeedback('Não foi possível cancelar o pedido.')
    } finally {
      setCancelling(false)
    }
  }

  return (
    <div>
      <Link to="/customer/orders" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para busca de pedidos
      </Link>

      <PageTitle title={`Status do pedido: ${id}`} subtitle="Histórico de transições e rastreamento" />

      {error && (
        <ErrorState
          title="Erro ao carregar rastreamento"
          message="Não foi possível consultar os dados deste pedido."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando rastreamento..." />}

      {!loading && !error && tracking && (
        <div className="space-y-8 max-w-3xl">
          {/* Card de Status Atual */}
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
            <div className="flex items-center justify-between flex-wrap gap-4 mb-4">
              <div>
                <p className="text-sm font-bold text-black/50">Estado atual</p>
                <div className="mt-1">
                  <Badge status={tracking.order_state} />
                </div>
              </div>

              {tracking.order_state === 'pending' && (
                <Button variant="danger" onClick={() => setCancelModalOpen(true)}>
                  Cancelar pedido
                </Button>
              )}
            </div>

            {feedback && (
              <div className="mt-4 p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
                {feedback}
              </div>
            )}
          </div>

          {/* Localização do Courier (se disponível) */}
          {tracking.courier_location && (
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-2">
              <h3 className="font-black italic text-2xl text-brutal-black">🛵 Courier próximo</h3>
              <p className="font-bold text-lg text-black/80">
                Última posição registrada:{' '}
                <span className="font-mono text-brutal-red">
                  {tracking.courier_location.latitude}, {tracking.courier_location.longitude}
                </span>
              </p>
              <p className="text-sm text-black/50 font-bold">
                Atualizado às{' '}
                {new Date(tracking.courier_location.recorded_at).toLocaleTimeString('pt-BR')} (atualizações periódicas)
              </p>
            </div>
          )}

          {/* Timeline de Histórico */}
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
            <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
              Histórico do pedido
            </h3>

            <div className="space-y-6">
              {tracking.history.map((step, idx) => (
                <div key={idx} className="flex items-start gap-4">
                  <div className="w-4 h-4 rounded-full border-2 border-brutal-black bg-brutal-red mt-1" />
                  <div>
                    <div className="font-black italic text-lg text-brutal-black capitalize">
                      {step.state}
                    </div>
                    <p className="text-sm font-bold text-black/50">
                      {new Date(step.at).toLocaleString('pt-BR')} {step.actor ? `• por ${step.actor}` : ''}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={cancelModalOpen}
        title="Cancelar pedido?"
        message="Tem certeza que deseja cancelar este pedido? Esta ação não pode ser desfeita."
        confirmLabel="Cancelar"
        onConfirm={handleCancel}
        onCancel={() => setCancelModalOpen(false)}
        loading={cancelling}
      />
    </div>
  )
}

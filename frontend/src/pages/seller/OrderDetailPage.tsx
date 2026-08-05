import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  getSellerOrder,
  acceptSellerOrder,
  rejectSellerOrder,
  preparingSellerOrder,
  readySellerOrder,
} from '../../services/sellerOrders'
import type { SellerOrder } from '../../services/sellerOrders'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function OrderDetailPage() {
  const { id = '' } = useParams()
  const [order, setOrder] = useState<SellerOrder | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [transitioning, setTransitioning] = useState(false)
  const [rejectModalOpen, setRejectModalOpen] = useState(false)
  const [rejectReason, setRejectReason] = useState('')
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getSellerOrder(id)
      .then(setOrder)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleAccept = async () => {
    setTransitioning(true)
    setFeedback(null)
    try {
      const updated = await acceptSellerOrder(id)
      setOrder(updated)
      setFeedback('Pedido aceito com sucesso!')
    } catch {
      setFeedback('Erro ao aceitar pedido.')
    } finally {
      setTransitioning(false)
    }
  }

  const handlePreparing = async () => {
    setTransitioning(true)
    setFeedback(null)
    try {
      const updated = await preparingSellerOrder(id)
      setOrder(updated)
      setFeedback('Pedido em preparação!')
    } catch {
      setFeedback('Erro ao alterar status para preparação.')
    } finally {
      setTransitioning(false)
    }
  }

  const handleReady = async () => {
    setTransitioning(true)
    setFeedback(null)
    try {
      const updated = await readySellerOrder(id)
      setOrder(updated)
      setFeedback('Pedido marcado como pronto para entrega!')
    } catch {
      setFeedback('Erro ao alterar status para pronto.')
    } finally {
      setTransitioning(false)
    }
  }

  const handleRejectConfirm = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!rejectReason.trim()) return
    setTransitioning(true)
    setFeedback(null)
    try {
      const updated = await rejectSellerOrder(id, rejectReason.trim())
      setOrder(updated)
      setRejectModalOpen(false)
      setRejectReason('')
      setFeedback('Pedido rejeitado.')
    } catch {
      setFeedback('Erro ao rejeitar pedido.')
    } finally {
      setTransitioning(false)
    }
  }

  return (
    <div>
      <Link to="/seller/orders" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para lista de pedidos
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar pedido"
          message="Não foi possível carregar os detalhes do pedido."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando pedido..." />}

      {!loading && !error && order && (
        <div className="space-y-6 max-w-4xl">
          {/* Header e Ações */}
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex items-start justify-between flex-wrap gap-4">
            <div>
              <PageTitle title={`Pedido #${order.id.slice(0, 8)}`} subtitle={`Cliente: ${order.customer_name ?? 'Anônimo'}`} />
              <p className="text-sm font-bold text-black/50">
                Recebido em {new Date(order.created_at).toLocaleString('pt-BR')}
              </p>
            </div>

            <div className="flex flex-col items-end gap-3">
              <Badge status={order.status} />

              <div className="flex flex-wrap gap-2">
                {order.status === 'pending' && (
                  <>
                    <Button variant="primary" loading={transitioning} onClick={handleAccept}>
                      Aceitar pedido
                    </Button>
                    <Button variant="danger" loading={transitioning} onClick={() => setRejectModalOpen(true)}>
                      Rejeitar pedido
                    </Button>
                  </>
                )}
                {order.status === 'accepted' && (
                  <Button variant="primary" loading={transitioning} onClick={handlePreparing}>
                    Iniciar preparo →
                  </Button>
                )}
                {order.status === 'preparing' && (
                  <Button variant="primary" loading={transitioning} onClick={handleReady}>
                    Pronto para entrega →
                  </Button>
                )}
              </div>
            </div>
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          {/* Itens e Totais */}
          <div className="grid md:grid-cols-3 gap-6">
            <div className="md:col-span-2 border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Itens solicitados
              </h3>

              <div className="divide-y-2 divide-black/10">
                {order.items.map((item) => (
                  <div key={item.id} className="py-3 flex justify-between items-center">
                    <div>
                      <p className="font-black italic text-lg text-brutal-black">{item.name}</p>
                      <p className="text-sm font-bold text-black/60">
                        {item.quantity}x {formatMoney(item.price_cents, item.currency)}
                      </p>
                    </div>
                    <p className="font-black italic text-lg text-brutal-black">
                      {formatMoney(item.price_cents * item.quantity, item.currency)}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-3">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Resumo financeiro
              </h3>

              <div className="flex justify-between font-bold text-black/70">
                <span>Subtotal</span>
                <span>{formatMoney(order.subtotal_cents, order.currency)}</span>
              </div>

              <div className="flex justify-between font-bold text-black/70">
                <span>Taxa de entrega</span>
                <span>{formatMoney(order.delivery_fee_cents, order.currency)}</span>
              </div>

              <div className="flex justify-between font-black italic text-2xl text-brutal-black border-t-4 border-brutal-black pt-3">
                <span>Total</span>
                <span className="text-brutal-red">{formatMoney(order.total_cents, order.currency)}</span>
              </div>
            </div>
          </div>

          {/* Histórico */}
          {order.history && order.history.length > 0 && (
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Histórico de transições
              </h3>

              <div className="space-y-4">
                {order.history.map((h, idx) => (
                  <div key={idx} className="flex items-start gap-4">
                    <div className="w-4 h-4 rounded-full border-2 border-brutal-black bg-brutal-black mt-1" />
                    <div>
                      <p className="font-black italic text-lg capitalize">{h.state}</p>
                      <p className="text-sm font-bold text-black/50">
                        {new Date(h.at).toLocaleString('pt-BR')} {h.actor ? `• por ${h.actor}` : ''}
                      </p>
                      {h.reason && <p className="text-sm text-brutal-red font-bold mt-1">Motivo: {h.reason}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Modal de Rejeição */}
      <Modal
        open={rejectModalOpen}
        onClose={() => setRejectModalOpen(false)}
        title="Rejeitar pedido?"
      >
        <form onSubmit={handleRejectConfirm} className="space-y-4">
          <Input
            label="Motivo da rejeição"
            placeholder="Ex: Falta de ingrediente, horário encerrado..."
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            required
          />

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setRejectModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="danger" type="submit" loading={transitioning}>
              Rejeitar
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

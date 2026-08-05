import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getAdminOrder, cancelAdminOrder } from '../../services/adminOps'
import type { SellerOrder } from '../../services/sellerOrders'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'

export default function OrderDetailPage() {
  const { id = '' } = useParams()
  const [order, setOrder] = useState<SellerOrder | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [cancelModalOpen, setCancelModalOpen] = useState(false)
  const [cancelling, setCancelling] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminOrder(id)
      .then(setOrder)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleCancelOrder = async () => {
    setCancelling(true)
    setFeedback(null)
    try {
      const updated = await cancelAdminOrder(id, 'Cancelado pelo administrador')
      setOrder(updated)
      setCancelModalOpen(false)
      setFeedback('Pedido cancelado pelo administrador.')
    } catch {
      setFeedback('Erro ao cancelar pedido.')
    } finally {
      setCancelling(false)
    }
  }

  return (
    <div>
      <Link to="/admin/orders" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para lista de pedidos
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar pedido"
          message="Não foi possível buscar as informações do pedido."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando pedido..." />}

      {!loading && !error && order && (
        <div className="max-w-4xl space-y-6">
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex items-start justify-between flex-wrap gap-4">
            <div>
              <PageTitle title={`Pedido #${order.id.slice(0, 8)}`} subtitle={`Cliente: ${order.customer_name ?? 'Anônimo'}`} />
              <p className="text-xs font-mono text-black/40">ID completo: {order.id}</p>
              <p className="text-sm font-bold text-black/50 mt-1">
                Data: {new Date(order.created_at).toLocaleString('pt-BR')}
              </p>
            </div>

            <div className="flex flex-col items-end gap-3">
              <Badge status={order.status} />

              {order.status !== 'cancelled' && order.status !== 'delivered' && (
                <Button variant="danger" loading={cancelling} onClick={() => setCancelModalOpen(true)}>
                  Cancelar pedido
                </Button>
              )}
            </div>
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          <div className="grid md:grid-cols-3 gap-6">
            <div className="md:col-span-2 border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Itens do pedido
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
                Valores discriminados
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
        </div>
      )}

      <ConfirmDialog
        open={cancelModalOpen}
        title="Cancelar pedido?"
        message="Deseja realmente cancelar este pedido como administrador? Esta ação é irreversível."
        confirmLabel="Cancelar"
        onConfirm={handleCancelOrder}
        onCancel={() => setCancelModalOpen(false)}
        loading={cancelling}
      />
    </div>
  )
}

import { useEffect, useState } from 'react'
import {
  getActiveDelivery,
  getEligibleDeliveries,
  acceptDelivery,
  pickupDelivery,
  completeDelivery,
} from '../../services/courierDeliveries'
import type { CourierOrder } from '../../services/courierDeliveries'
import { formatMoney } from '../../lib/money'
import { unwrapError } from '../../services/api'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'

export default function DeliveriesPage() {
  const [activeOrder, setActiveOrder] = useState<CourierOrder | null>(null)
  const [eligibleOrders, setEligibleOrders] = useState<CourierOrder[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [actingId, setActingId] = useState<string | null>(null)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    Promise.all([getActiveDelivery(), getEligibleDeliveries()])
      .then(([active, eligible]) => {
        setActiveOrder(active)
        setEligibleOrders(eligible)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleAccept = async (id: string) => {
    setActingId(id)
    setFeedback(null)
    try {
      await acceptDelivery(id)
      setFeedback('Entrega aceita com sucesso!')
      load()
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.code === 'conflict' || apiErr.code === 'order_already_assigned') {
        setFeedback('Esta entrega já foi aceita por outro entregador.')
      } else {
        setFeedback(apiErr.message || 'Erro ao aceitar entrega.')
      }
    } finally {
      setActingId(null)
    }
  }

  const handlePickup = async (id: string) => {
    setActingId(id)
    setFeedback(null)
    try {
      await pickupDelivery(id)
      setFeedback('Coleta confirmada!')
      load()
    } catch {
      setFeedback('Erro ao confirmar coleta.')
    } finally {
      setActingId(null)
    }
  }

  const handleDeliver = async (id: string) => {
    setActingId(id)
    setFeedback(null)
    try {
      await completeDelivery(id)
      setFeedback('Entrega concluída com sucesso!')
      load()
    } catch {
      setFeedback('Erro ao confirmar entrega.')
    } finally {
      setActingId(null)
    }
  }

  return (
    <div>
      <PageTitle title="Painel de Entregas" subtitle="Gerencie sua entrega ativa e veja corridas disponíveis" />

      {error && (
        <ErrorState
          title="Erro ao carregar entregas"
          message="Não foi possível buscar as entregas no momento."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando entregas..." />}

      {feedback && (
        <div className="mb-6 p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
          {feedback}
        </div>
      )}

      {!loading && !error && (
        <div className="space-y-10 max-w-4xl">
          {/* Seção 1: Entrega Ativa */}
          {activeOrder && (
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] border-l-8 border-l-brutal-red space-y-4">
              <div className="flex items-center justify-between flex-wrap gap-4 border-b-4 border-brutal-black pb-4">
                <div>
                  <span className="font-bold text-xs uppercase tracking-wider text-brutal-red">
                    Sua Entrega em Andamento
                  </span>
                  <h3 className="font-black italic text-3xl text-brutal-black mt-1">
                    Pedido #{activeOrder.id.slice(0, 8)}
                  </h3>
                </div>
                <Badge status={activeOrder.order_state} />
              </div>

              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-bold text-black/50">Restaurante / Seller</p>
                  <p className="font-black italic text-xl">{activeOrder.seller_name ?? '—'}</p>
                </div>

                <div>
                  <p className="text-sm font-bold text-black/50">Endereço de entrega</p>
                  <p className="font-bold text-base">{activeOrder.delivery_address ?? '—'}</p>
                </div>
              </div>

              <div className="flex items-center justify-between border-t-4 border-brutal-black pt-4 flex-wrap gap-4">
                <div>
                  <p className="text-sm font-bold text-black/50">Seu ganho nesta corrida</p>
                  <p className="font-black italic text-3xl text-brutal-red">
                    {formatMoney(activeOrder.courier_fee_cents, activeOrder.currency)}
                  </p>
                </div>

                <div className="flex gap-3">
                  {activeOrder.order_state === 'assigned' && (
                    <Button
                      variant="primary"
                      size="lg"
                      loading={actingId === activeOrder.id}
                      onClick={() => handlePickup(activeOrder.id)}
                    >
                      Confirmar coleta →
                    </Button>
                  )}
                  {activeOrder.order_state === 'picked_up' && (
                    <Button
                      variant="primary"
                      size="lg"
                      loading={actingId === activeOrder.id}
                      onClick={() => handleDeliver(activeOrder.id)}
                    >
                      Confirmar entrega →
                    </Button>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Seção 2: Entregas Disponíveis */}
          <div>
            <h3 className="font-black italic text-2xl text-brutal-black mb-4">Entregas disponíveis</h3>

            {eligibleOrders.length === 0 ? (
              <EmptyState
                title="Nenhuma entrega disponível"
                description="Fique atento! Novas corridas surgirão assim que os restaurantes finalizarem os pedidos."
              />
            ) : (
              <div className="space-y-4">
                {eligibleOrders.map((o) => (
                  <div
                    key={o.id}
                    className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex flex-wrap items-center justify-between gap-4"
                  >
                    <div>
                      <div className="flex items-center gap-3 mb-1">
                        <span className="font-mono text-sm font-bold text-black/40">#{o.id.slice(0, 8)}</span>
                        <Badge status={o.order_state} />
                      </div>
                      <h4 className="font-black italic text-xl text-brutal-black">
                        {o.seller_name ?? 'Restaurante'}
                      </h4>
                      {o.delivery_address && (
                        <p className="text-sm font-bold text-black/60 mt-1">📍 {o.delivery_address}</p>
                      )}
                    </div>

                    <div className="flex items-center gap-6">
                      <div className="text-right">
                        <p className="text-xs font-bold text-black/50 uppercase">Ganho estimado</p>
                        <p className="font-black italic text-2xl text-brutal-red">
                          {formatMoney(o.courier_fee_cents, o.currency)}
                        </p>
                      </div>

                      <Button
                        variant="primary"
                        disabled={Boolean(activeOrder)}
                        loading={actingId === o.id}
                        onClick={() => handleAccept(o.id)}
                      >
                        Aceitar entrega
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

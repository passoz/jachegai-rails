import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  getCustomerCart,
  clearCustomerCart,
  updateCustomerCartItem,
  removeCustomerCartItem,
  handoffGuestCart,
} from '../../services/customerCart'
import type { CustomerCart } from '../../services/customerCart'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'

export default function CartPage() {
  const [cart, setCart] = useState<CustomerCart | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [updatingId, setUpdatingId] = useState<string | null>(null)

  const [clearDialogOpen, setClearDialogOpen] = useState(false)
  const [clearing, setClearing] = useState(false)

  const navigate = useNavigate()

  const load = async () => {
    setLoading(true)
    setError(false)
    try {
      // Handoff automático ao carregar
      await handoffGuestCart().catch(() => null)
      const data = await getCustomerCart()
      setCart(data)
    } catch {
      setError(true)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const handleUpdateQuantity = async (itemId: string, newQty: number) => {
    if (newQty < 1) return
    setUpdatingId(itemId)
    try {
      const updated = await updateCustomerCartItem(itemId, newQty)
      setCart(updated)
    } catch {
      // keep
    } finally {
      setUpdatingId(null)
    }
  }

  const handleRemoveItem = async (itemId: string) => {
    setUpdatingId(itemId)
    try {
      const updated = await removeCustomerCartItem(itemId)
      setCart(updated)
    } catch {
      // keep
    } finally {
      setUpdatingId(null)
    }
  }

  const handleClearCart = async () => {
    setClearing(true)
    try {
      await clearCustomerCart()
      setCart({
        items: [],
        subtotal_cents: 0,
        delivery_fee_cents: 0,
        total_cents: 0,
        currency: 'BRL',
      })
      setClearDialogOpen(false)
    } catch {
      // keep
    } finally {
      setClearing(false)
    }
  }

  return (
    <div>
      <PageTitle title="Meu carrinho" subtitle="Revise seus itens e avance para o checkout" />

      {error && (
        <ErrorState
          title="Erro ao carregar carrinho"
          message="Não foi possível carregar o seu carrinho."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando carrinho..." />}

      {!loading && !error && cart && cart.items.length === 0 && (
        <EmptyState
          title="Seu carrinho está vazio"
          description="Adicione produtos para começar seu pedido."
          action={
            <Link to="/sellers">
              <Button variant="primary">Explorar sellers</Button>
            </Link>
          }
        />
      )}

      {!loading && !error && cart && cart.items.length > 0 && (
        <div className="grid lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-4">
            {cart.items.map((item) => (
              <div
                key={item.id}
                className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex flex-wrap items-center justify-between gap-4"
              >
                <div className="flex-1 min-w-[200px]">
                  <h3 className="font-black italic text-xl text-brutal-black">{item.name}</h3>
                  <p className="text-black/60 text-sm mt-1">
                    {formatMoney(item.price_cents, item.currency)} cada
                  </p>
                </div>

                <div className="flex items-center gap-3">
                  <div className="flex items-center border-4 border-brutal-black rounded-[1.5rem] overflow-hidden bg-white">
                    <button
                      type="button"
                      aria-label="Diminuir quantidade"
                      disabled={updatingId === item.id || item.quantity <= 1}
                      onClick={() => handleUpdateQuantity(item.id, item.quantity - 1)}
                      className="px-3 py-1 font-black text-lg hover:bg-brutal-red transition-colors disabled:opacity-50"
                    >
                      −
                    </button>
                    <span className="px-4 font-black italic text-lg">{item.quantity}</span>
                    <button
                      type="button"
                      aria-label="Aumentar quantidade"
                      disabled={updatingId === item.id}
                      onClick={() => handleUpdateQuantity(item.id, item.quantity + 1)}
                      className="px-3 py-1 font-black text-lg hover:bg-brutal-red transition-colors disabled:opacity-50"
                    >
                      +
                    </button>
                  </div>

                  <p className="font-black italic text-xl text-brutal-black min-w-[90px] text-right">
                    {formatMoney(item.price_cents * item.quantity, item.currency)}
                  </p>

                  <Button
                    variant="danger"
                    size="sm"
                    loading={updatingId === item.id}
                    onClick={() => handleRemoveItem(item.id)}
                  >
                    Remover
                  </Button>
                </div>
              </div>
            ))}
          </div>

          <div>
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Resumo do pedido
              </h3>

              <div className="flex justify-between font-bold text-black/70">
                <span>Subtotal</span>
                <span>{formatMoney(cart.subtotal_cents, cart.currency)}</span>
              </div>

              <div className="flex justify-between font-bold text-black/70">
                <span>Taxa de entrega</span>
                <span>{formatMoney(cart.delivery_fee_cents, cart.currency)}</span>
              </div>

              <div className="flex justify-between font-black italic text-2xl text-brutal-black border-t-4 border-brutal-black pt-3">
                <span>Total</span>
                <span className="text-brutal-red">{formatMoney(cart.total_cents, cart.currency)}</span>
              </div>

              <Button
                variant="primary"
                className="w-full mt-4 text-lg"
                onClick={() => navigate('/customer/checkout')}
              >
                Finalizar compra →
              </Button>

              <Button
                variant="outline"
                className="w-full text-sm"
                onClick={() => setClearDialogOpen(true)}
              >
                Limpar carrinho
              </Button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={clearDialogOpen}
        title="Limpar carrinho?"
        message="Tem certeza que deseja remover todos os itens do carrinho?"
        confirmLabel="Limpar"
        onConfirm={handleClearCart}
        onCancel={() => setClearDialogOpen(false)}
        loading={clearing}
      />
    </div>
  )
}

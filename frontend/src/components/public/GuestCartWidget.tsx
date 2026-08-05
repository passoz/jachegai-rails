import { useCallback, useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { getCart, clearCart, updateCartItem, removeCartItem } from '../../services/cart'
import type { CartResponse } from '../../services/cart'
import { formatMoney } from '../../lib/money'
import Button from '../ui/Button'
import LoadingSpinner from '../ui/LoadingSpinner'
import EmptyState from '../ui/EmptyState'

export default function GuestCartWidget() {
  const [cart, setCart] = useState<CartResponse | null>(null)
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const panelRef = useRef<HTMLDivElement>(null)

  const load = useCallback(async () => {
    try {
      const data = await getCart()
      setCart(data)
    } catch {
      setCart(null)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  useEffect(() => {
    if (open && cart === null) load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  const toggle = () => setOpen((v) => !v)

  const handleRemove = async (itemId: string) => {
    setLoading(true)
    try {
      const data = await removeCartItem(itemId)
      setCart(data)
    } catch {
      // keep current state
    } finally {
      setLoading(false)
    }
  }

  const handleUpdate = async (itemId: string, quantity: number) => {
    if (quantity < 1) return
    setLoading(true)
    try {
      const data = await updateCartItem(itemId, quantity)
      setCart(data)
    } catch {
      // keep current state
    } finally {
      setLoading(false)
    }
  }

  const handleClear = async () => {
    setLoading(true)
    try {
      await clearCart()
      setCart({ items: [], total_cents: 0, currency: 'BRL' })
    } catch {
      // keep current state
    } finally {
      setLoading(false)
    }
  }

  const count = cart?.items.reduce((acc, item) => acc + item.quantity, 0) ?? 0

  return (
    <div className="relative">
      <button
        type="button"
        onClick={toggle}
        aria-label="Abrir carrinho"
        className="relative flex items-center gap-1 border-4 border-brutal-black rounded-[1.5rem] px-3 py-2 bg-white hover:bg-brutal-red hover:border-brutal-red transition-colors"
      >
        <span aria-hidden="true" className="text-lg">
          🛒
        </span>
        <span className="font-black italic">Carrinho</span>
        {count > 0 && (
          <span
            data-testid="cart-count"
            className="absolute -top-3 -right-3 bg-brutal-red border-4 border-brutal-black rounded-full w-8 h-8 flex items-center justify-center font-black italic text-sm"
          >
            {count}
          </span>
        )}
      </button>

      {open && (
        <>
          <div
            className="fixed inset-0 bg-black/60 z-40"
            aria-hidden="true"
            onClick={toggle}
          />
          <div
            ref={panelRef}
            role="dialog"
            aria-label="Carrinho"
            className="fixed top-0 right-0 h-full w-full max-w-md bg-white border-l-4 border-brutal-black z-50 flex flex-col shadow-[-8px_0_0_0_rgba(0,0,0,1)]"
          >
            <div className="flex items-center justify-between border-b-4 border-brutal-black p-4">
              <h2 className="font-black italic text-2xl text-brutal-black">Meu carrinho</h2>
              <button
                type="button"
                onClick={toggle}
                aria-label="Fechar carrinho"
                className="border-4 border-brutal-black rounded-[1.5rem] px-3 py-1 font-black italic hover:bg-brutal-red transition-colors"
              >
                ✕
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              {cart === null && <LoadingSpinner label="Carregando carrinho..." />}
              {cart !== null && cart.items.length === 0 && (
                <EmptyState title="Carrinho vazio" description="Adicione produtos para começar seu pedido." />
              )}
              {cart !== null &&
                cart.items.map((item) => (
                  <div
                    key={item.id}
                    className="border-4 border-brutal-black rounded-[1.5rem] p-4 bg-brutal-gray"
                  >
                    <div className="flex justify-between items-start gap-2">
                      <div>
                        <p className="font-black italic text-lg text-brutal-black">
                          {item.name ?? 'Produto'}
                        </p>
                        {item.price_cents !== undefined && (
                          <p className="text-sm text-black/60 mt-1">
                            {formatMoney(item.price_cents, item.currency ?? 'BRL')} cada
                          </p>
                        )}
                      </div>
                      <button
                        type="button"
                        aria-label={`Remover ${item.name ?? 'item'}`}
                        className="font-black text-brutal-red hover:underline"
                        onClick={() => handleRemove(item.id)}
                        disabled={loading}
                      >
                        Remover
                      </button>
                    </div>
                    <div className="flex items-center gap-2 mt-3">
                      <button
                        type="button"
                        aria-label={`Diminuir ${item.name ?? 'item'}`}
                        className="border-4 border-brutal-black rounded-full w-8 h-8 font-black hover:bg-brutal-red transition-colors"
                        onClick={() => handleUpdate(item.id, item.quantity - 1)}
                        disabled={loading}
                      >
                        −
                      </button>
                      <span data-testid={`qty-${item.id}`} className="font-black italic w-6 text-center">
                        {item.quantity}
                      </span>
                      <button
                        type="button"
                        aria-label={`Aumentar ${item.name ?? 'item'}`}
                        className="border-4 border-brutal-black rounded-full w-8 h-8 font-black hover:bg-brutal-red transition-colors"
                        onClick={() => handleUpdate(item.id, item.quantity + 1)}
                        disabled={loading}
                      >
                        +
                      </button>
                    </div>
                  </div>
                ))}
            </div>

            <div className="border-t-4 border-brutal-black p-4 space-y-3">
              {cart !== null && cart.items.length > 0 && (
                <>
                  <div className="flex justify-between items-center">
                    <span className="font-black italic text-lg">Total</span>
                    <span className="font-black italic text-2xl text-brutal-red">
                      {formatMoney(cart.total_cents, cart.currency)}
                    </span>
                  </div>
                  <Button variant="primary" className="w-full" onClick={() => undefined}>
                    Fazer login para finalizar
                  </Button>
                  <div className="flex justify-between items-center">
                    <Link to="/login" className="text-sm font-bold text-brutal-red hover:underline">
                      Já tem conta? Entrar
                    </Link>
                    <button
                      type="button"
                      className="text-sm font-black underline hover:text-brutal-red"
                      onClick={handleClear}
                      disabled={loading}
                    >
                      Limpar carrinho
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getProduct } from '../services/public'
import { addCartItem } from '../services/cart'
import type { PublicProduct } from '../types/public'
import { formatMoney } from '../lib/money'
import LoadingSpinner from '../components/ui/LoadingSpinner'
import ErrorState from '../components/ui/ErrorState'
import Button from '../components/ui/Button'

export default function ProductDetailPage() {
  const { id = '' } = useParams()
  const [product, setProduct] = useState<PublicProduct | null>(null)
  const [error, setError] = useState(false)
  const [quantity, setQuantity] = useState(1)
  const [adding, setAdding] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setError(false)
    setProduct(null)
    getProduct(id)
      .then(setProduct)
      .catch(() => setError(true))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleAdd = async () => {
    if (!product) return
    setAdding(true)
    setFeedback(null)
    try {
      await addCartItem(product.id, quantity)
      setFeedback('Produto adicionado ao carrinho!')
    } catch {
      setFeedback('Não foi possível adicionar ao carrinho.')
    } finally {
      setAdding(false)
    }
  }

  return (
    <div>
      {error && (
        <ErrorState
          title="Não foi possível carregar o produto"
          message="O produto pode não existir ou a conexão falhou."
          onRetry={load}
        />
      )}
      {!error && product === null && <LoadingSpinner label="Carregando produto..." />}
      {!error && product !== null && (
        <section className="border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white p-8 md:p-12">
          <Link to={`/sellers/${product.seller_id}`} className="font-bold text-brutal-red hover:underline">
            ← Ver loja
          </Link>
          <h1 className="font-black italic text-4xl md:text-5xl text-brutal-black mt-4 mb-4">
            {product.name}
          </h1>
          {product.description && (
            <p className="text-black/60 text-lg max-w-2xl mb-6">{product.description}</p>
          )}
          <p className="text-4xl font-black italic text-brutal-red mb-8">
            {formatMoney(product.price_cents, product.currency)}
          </p>

          <div className="flex flex-wrap items-center gap-4">
            <div className="flex items-center border-4 border-brutal-black rounded-[1.5rem] overflow-hidden">
              <button
                type="button"
                aria-label="Diminuir quantidade"
                className="px-4 py-2 font-black text-xl bg-brutal-gray hover:bg-brutal-red transition-colors"
                onClick={() => setQuantity((q) => Math.max(1, q - 1))}
              >
                −
              </button>
              <span className="px-6 font-black italic text-xl" data-testid="quantity">
                {quantity}
              </span>
              <button
                type="button"
                aria-label="Aumentar quantidade"
                className="px-4 py-2 font-black text-xl bg-brutal-gray hover:bg-brutal-red transition-colors"
                onClick={() => setQuantity((q) => Math.min(10, q + 1))}
              >
                +
              </button>
            </div>
            <Button variant="primary" onClick={handleAdd} loading={adding}>
              Adicionar ao carrinho
            </Button>
          </div>
          {feedback && (
            <p className="mt-4 font-bold text-brutal-black" role="status">
              {feedback}
            </p>
          )}
        </section>
      )}
    </div>
  )
}

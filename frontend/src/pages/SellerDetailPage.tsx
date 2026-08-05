import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getSeller, listSellerProducts } from '../services/public'
import { addCartItem } from '../services/cart'
import type { PublicSeller, PublicProduct } from '../types/public'
import { formatMoney } from '../lib/money'
import { unwrapError } from '../services/api'
import LoadingSpinner from '../components/ui/LoadingSpinner'
import ErrorState from '../components/ui/ErrorState'
import EmptyState from '../components/ui/EmptyState'
import Badge from '../components/ui/Badge'
import Button from '../components/ui/Button'
import ConfirmDialog from '../components/ui/ConfirmDialog'

export default function SellerDetailPage() {
  const { id = '' } = useParams()
  const [seller, setSeller] = useState<PublicSeller | null>(null)
  const [products, setProducts] = useState<PublicProduct[] | null>(null)
  const [error, setError] = useState(false)
  const [addingId, setAddingId] = useState<string | null>(null)
  const [replaceProduct, setReplaceProduct] = useState<PublicProduct | null>(null)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setError(false)
    setSeller(null)
    setProducts(null)
    setFeedback(null)
    Promise.all([getSeller(id), listSellerProducts(id)])
      .then(([s, p]) => {
        setSeller(s)
        setProducts(p)
      })
      .catch(() => setError(true))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleAdd = async (product: PublicProduct, replaceConfirmed = false) => {
    setAddingId(product.id)
    setFeedback(null)
    try {
      await addCartItem(product.id, 1, replaceConfirmed)
      setFeedback('Produto adicionado ao carrinho!')
      setReplaceProduct(null)
    } catch (err) {
      const apiError = unwrapError(err)
      if (apiError.code === 'seller_conflict' && !replaceConfirmed) {
        setReplaceProduct(product)
      } else {
        setFeedback('Não foi possível adicionar ao carrinho.')
      }
    } finally {
      setAddingId(null)
    }
  }

  return (
    <div>
      {error && (
        <ErrorState
          title="Não foi possível carregar a loja"
          message="A loja pode não existir ou a conexão falhou."
          onRetry={load}
        />
      )}
      {!error && seller === null && <LoadingSpinner label="Carregando loja..." />}
      {!error && seller !== null && (
        <>
          <Link to="/sellers" className="font-bold text-brutal-red hover:underline">
            ← Voltar para sellers
          </Link>
          <section className="mt-4 border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white p-8 mb-10">
            <div className="flex items-start justify-between flex-wrap gap-4">
              <div>
                <h1 className="font-black italic text-4xl text-brutal-black">{seller.name}</h1>
                {seller.description && (
                  <p className="text-black/60 mt-2 max-w-2xl">{seller.description}</p>
                )}
                {(seller.address_city || seller.contact_email || seller.contact_phone) && (
                  <div className="mt-4 space-y-1 text-sm font-bold text-black/50">
                    {seller.address_city && (
                      <p>
                        📍 {seller.address_city}
                        {seller.address_state ? `, ${seller.address_state}` : ''}
                      </p>
                    )}
                    {seller.contact_email && <p>✉️ {seller.contact_email}</p>}
                    {seller.contact_phone && <p>📞 {seller.contact_phone}</p>}
                  </div>
                )}
              </div>
              {seller.moderation_state !== 'approved' && (
                <Badge status={seller.moderation_state} />
              )}
            </div>
          </section>

          <h2 className="font-black italic text-2xl text-brutal-black mb-4">Produtos</h2>
          {feedback && (
            <p className="mb-4 font-bold text-brutal-black" role="status">
              {feedback}
            </p>
          )}
          {products === null && <LoadingSpinner label="Carregando produtos..." />}
          {products !== null && products.length === 0 && (
            <EmptyState title="Nenhum produto disponível" description="Esta loja ainda não publicou produtos." />
          )}
          {products !== null && products.length > 0 && (
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {products.map((product) => (
                <div
                  key={product.id}
                  className="flex flex-col border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white p-6 hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5 transition-all"
                >
                  <Link to={`/products/${product.id}`} className="flex-1">
                    <h3 className="font-black italic text-xl text-brutal-black">{product.name}</h3>
                    {product.description && (
                      <p className="text-black/60 text-sm line-clamp-2 mt-1">{product.description}</p>
                    )}
                    <p className="mt-3 text-2xl font-black italic text-brutal-red">
                      {formatMoney(product.price_cents, product.currency)}
                    </p>
                  </Link>
                  <div className="mt-4">
                    <Button
                      variant="primary"
                      size="sm"
                      className="w-full"
                      loading={addingId === product.id}
                      onClick={() => handleAdd(product)}
                    >
                      Adicionar ao carrinho
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}

      <ConfirmDialog
        open={replaceProduct !== null}
        title="Substituir carrinho?"
        message="Seu carrinho será substituído. Continuar?"
        confirmLabel="Continuar"
        onConfirm={() => {
          if (replaceProduct) handleAdd(replaceProduct, true)
        }}
        onCancel={() => setReplaceProduct(null)}
      />
    </div>
  )
}

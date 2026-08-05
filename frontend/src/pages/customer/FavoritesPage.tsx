import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listCustomerFavorites, removeCustomerFavorite } from '../../services/customer'
import type { CustomerFavorite } from '../../types/customer'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'

export default function FavoritesPage() {
  const [favorites, setFavorites] = useState<CustomerFavorite[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [removingId, setRemovingId] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    listCustomerFavorites()
      .then(setFavorites)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleRemove = async (id: string) => {
    setRemovingId(id)
    try {
      await removeCustomerFavorite(id)
      setFavorites((prev) => (prev ? prev.filter((f) => f.id !== id) : []))
    } catch {
      // keep
    } finally {
      setRemovingId(null)
    }
  }

  return (
    <div>
      <PageTitle title="Meus favoritos" subtitle="Sellers que você curte e acompanha" />

      {error && (
        <ErrorState
          title="Erro ao carregar favoritos"
          message="Não foi possível carregar seus sellers favoritos."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando favoritos..." />}

      {!loading && !error && favorites && favorites.length === 0 && (
        <EmptyState
          title="Nenhum seller favoritado"
          description="Você ainda não salvou nenhum seller na sua lista."
          action={
            <Link to="/sellers">
              <Button variant="primary">Explorar sellers</Button>
            </Link>
          }
        />
      )}

      {!loading && !error && favorites && favorites.length > 0 && (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {favorites.map((fav) => (
            <div
              key={fav.id}
              className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex flex-col justify-between"
            >
              <div>
                <h3 className="font-black italic text-2xl text-brutal-black mb-2">
                  {fav.seller_name}
                </h3>
              </div>

              <div className="flex items-center justify-between gap-3 mt-6 pt-4 border-t-2 border-black/10">
                <Link to={`/sellers/${fav.seller_id}`}>
                  <Button variant="outline" size="sm">
                    Ver loja
                  </Button>
                </Link>
                <Button
                  variant="danger"
                  size="sm"
                  loading={removingId === fav.id}
                  onClick={() => handleRemove(fav.id)}
                >
                  Remover
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

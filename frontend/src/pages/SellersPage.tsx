import { useEffect, useState } from 'react'
import { listSellers } from '../services/public'
import type { PublicSeller } from '../types/public'
import SellerCard from '../components/public/SellerCard'
import LoadingSpinner from '../components/ui/LoadingSpinner'
import ErrorState from '../components/ui/ErrorState'
import EmptyState from '../components/ui/EmptyState'
import PageTitle from '../components/ui/PageTitle'
import Button from '../components/ui/Button'

export default function SellersPage() {
  const [sellers, setSellers] = useState<PublicSeller[] | null>(null)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [error, setError] = useState(false)

  const load = (targetPage = page) => {
    setError(false)
    setSellers(null)
    listSellers({ page: targetPage })
      .then((result) => {
        setSellers(result.sellers)
        setPage(targetPage)
        setTotalPages(result.pagination?.total_pages ?? 1)
      })
      .catch(() => setError(true))
  }

  useEffect(() => {
    load(1)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div>
      <PageTitle title="Descubra sellers" subtitle="Todos os sellers são verificados e aprovados pela nossa equipe." />
      {error && (
        <ErrorState
          title="Não foi possível carregar os sellers"
          message="Verifique sua conexão e tente novamente."
          onRetry={() => load()}
        />
      )}
      {!error && sellers === null && <LoadingSpinner label="Carregando sellers..." />}
      {!error && sellers !== null && sellers.length === 0 && (
        <EmptyState title="Nenhum seller disponível" description="Volte em breve." />
      )}
      {!error && sellers !== null && sellers.length > 0 && (
        <>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {sellers.map((seller) => (
              <SellerCard key={seller.id} seller={seller} />
            ))}
          </div>
          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-4 mt-10">
              <Button
                variant="outline"
                onClick={() => load(page - 1)}
                disabled={page <= 1}
              >
                ← Anterior
              </Button>
              <span className="font-black italic text-lg">
                Página {page} de {totalPages}
              </span>
              <Button
                variant="outline"
                onClick={() => load(page + 1)}
                disabled={page >= totalPages}
              >
                Próxima →
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  )
}

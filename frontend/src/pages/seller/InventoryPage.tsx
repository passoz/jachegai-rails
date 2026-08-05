import { useEffect, useState } from 'react'
import { listSellerProducts, updateSellerInventory } from '../../services/sellerCatalog'
import type { SellerProduct } from '../../services/sellerCatalog'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import Table from '../../components/ui/Table'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'

export default function InventoryPage() {
  const [products, setProducts] = useState<SellerProduct[] | null>(null)
  const [quantities, setQuantities] = useState<Record<string, number>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [updatingId, setUpdatingId] = useState<string | null>(null)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    listSellerProducts()
      .then((prods) => {
        setProducts(prods)
        const qMap: Record<string, number> = {}
        prods.forEach((p) => {
          qMap[p.id] = p.quantity ?? 0
        })
        setQuantities(qMap)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleUpdate = async (productId: string) => {
    const qty = quantities[productId] ?? 0
    if (qty < 0) return

    setUpdatingId(productId)
    setFeedback(null)
    try {
      await updateSellerInventory(productId, qty)
      setFeedback('Estoque atualizado com sucesso!')
    } catch {
      setFeedback('Erro ao atualizar estoque.')
    } finally {
      setUpdatingId(null)
    }
  }

  const tableColumns = [
    {
      key: 'name',
      header: 'Produto',
      render: (p: SellerProduct) => <span className="font-black italic text-lg">{p.name}</span>,
    },
    {
      key: 'current_qty',
      header: 'Estoque Atual',
      render: (p: SellerProduct) => (
        <span className="font-mono font-bold text-lg">{p.quantity ?? 0} un.</span>
      ),
    },
    {
      key: 'new_qty',
      header: 'Nova Quantidade',
      render: (p: SellerProduct) => (
        <input
          type="number"
          min="0"
          value={quantities[p.id] ?? 0}
          onChange={(e) =>
            setQuantities({
              ...quantities,
              [p.id]: parseInt(e.target.value, 10) || 0,
            })
          }
          className="border-4 border-brutal-black rounded-[1rem] px-4 py-2 w-32 text-center font-bold text-lg bg-white"
        />
      ),
    },
    {
      key: 'actions',
      header: 'Ação',
      render: (p: SellerProduct) => (
        <Button
          variant="primary"
          size="sm"
          loading={updatingId === p.id}
          onClick={() => handleUpdate(p.id)}
        >
          Atualizar
        </Button>
      ),
    },
  ]

  return (
    <div>
      <PageTitle title="Estoque" subtitle="Ajuste a quantidade disponível para cada produto" />

      {error && (
        <ErrorState
          title="Erro ao carregar estoque"
          message="Não foi possível exibir o estoque dos produtos."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando estoque..." />}

      {feedback && (
        <div className="mb-6 p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
          {feedback}
        </div>
      )}

      {!loading && !error && products && products.length === 0 && (
        <EmptyState
          title="Nenhum produto no catálogo"
          description="Você precisa cadastrar produtos para gerenciar o estoque."
        />
      )}

      {!loading && !error && products && products.length > 0 && (
        <Table columns={tableColumns} data={products} />
      )}
    </div>
  )
}

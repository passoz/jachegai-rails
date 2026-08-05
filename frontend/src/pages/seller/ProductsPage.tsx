import { useEffect, useState } from 'react'
import {
  listSellerProducts,
  listSellerCategories,
  createSellerProduct,
  updateSellerProduct,
  deleteSellerProduct,
  activateSellerProduct,
  deactivateSellerProduct,
} from '../../services/sellerCatalog'
import type { SellerProduct, SellerCategory, ProductPayload } from '../../services/sellerCatalog'
import { formatMoney } from '../../lib/money'
import { unwrapError } from '../../services/api'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Table from '../../components/ui/Table'
import Badge from '../../components/ui/Badge'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'

export default function ProductsPage() {
  const [products, setProducts] = useState<SellerProduct[] | null>(null)
  const [categories, setCategories] = useState<SellerCategory[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState<SellerProduct | null>(null)
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [priceInput, setPriceInput] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [saving, setSaving] = useState(false)
  const [modalError, setModalError] = useState<string | null>(null)

  const [deleteTarget, setDeleteTarget] = useState<SellerProduct | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [togglingId, setTogglingId] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    Promise.all([listSellerProducts(), listSellerCategories()])
      .then(([prods, cats]) => {
        setProducts(prods)
        setCategories(cats)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const parsePriceToCents = (val: string): number => {
    const clean = val.replace(/[^\d,.]/g, '').replace(',', '.')
    const num = parseFloat(clean)
    return isNaN(num) ? 0 : Math.round(num * 100)
  }

  const openNewModal = () => {
    setEditingProduct(null)
    setName('')
    setDescription('')
    setPriceInput('')
    setCategoryId(categories[0]?.id ?? '')
    setModalError(null)
    setModalOpen(true)
  }

  const openEditModal = (p: SellerProduct) => {
    setEditingProduct(p)
    setName(p.name)
    setDescription(p.description ?? '')
    setPriceInput((p.price_cents / 100).toFixed(2).replace('.', ','))
    setCategoryId(p.category_id ?? '')
    setModalError(null)
    setModalOpen(true)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setModalError(null)

    const cents = parsePriceToCents(priceInput)
    if (cents <= 0) {
      setModalError('Informe um preço válido maior que zero.')
      setSaving(false)
      return
    }

    const payload: ProductPayload = {
      name,
      description: description || undefined,
      price_cents: cents,
      currency: 'BRL',
      category_id: categoryId || undefined,
    }

    try {
      if (editingProduct) {
        await updateSellerProduct(editingProduct.id, payload)
      } else {
        await createSellerProduct(payload)
      }
      setModalOpen(false)
      load()
    } catch (err) {
      const apiErr = unwrapError(err)
      setModalError(apiErr.message || 'Erro ao salvar produto.')
    } finally {
      setSaving(false)
    }
  }

  const handleToggleActive = async (p: SellerProduct) => {
    setTogglingId(p.id)
    try {
      if (p.active) {
        await deactivateSellerProduct(p.id)
      } else {
        await activateSellerProduct(p.id)
      }
      load()
    } catch {
      // keep
    } finally {
      setTogglingId(null)
    }
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await deleteSellerProduct(deleteTarget.id)
      setDeleteTarget(null)
      load()
    } catch {
      // keep
    } finally {
      setDeleting(false)
    }
  }

  const categoryMap = new Map(categories.map((c) => [c.id, c.name]))

  const tableColumns = [
    { key: 'name', header: 'Produto', render: (p: SellerProduct) => <span className="font-black italic">{p.name}</span> },
    {
      key: 'category',
      header: 'Categoria',
      render: (p: SellerProduct) => categoryMap.get(p.category_id ?? '') ?? '—',
    },
    {
      key: 'price',
      header: 'Preço',
      render: (p: SellerProduct) => (
        <span className="font-mono font-bold text-brutal-red">
          {formatMoney(p.price_cents, p.currency)}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (p: SellerProduct) => <Badge status={p.active ? 'active' : 'inactive'} />,
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (p: SellerProduct) => (
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            loading={togglingId === p.id}
            onClick={() => handleToggleActive(p)}
          >
            {p.active ? 'Desativar' : 'Ativar'}
          </Button>
          <Button variant="outline" size="sm" onClick={() => openEditModal(p)}>
            Editar
          </Button>
          <Button variant="danger" size="sm" onClick={() => setDeleteTarget(p)}>
            Excluir
          </Button>
        </div>
      ),
    },
  ]

  return (
    <div>
      <div className="flex items-center justify-between flex-wrap gap-4 mb-6">
        <PageTitle title="Produtos" subtitle="Gerencie os itens à venda em sua loja" />
        <Button variant="primary" onClick={openNewModal}>
          Novo produto
        </Button>
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar produtos"
          message="Não foi possível exibir o seu catálogo."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando produtos..." />}

      {!loading && !error && products && products.length === 0 && (
        <EmptyState
          title="Nenhum produto cadastrado"
          description="Cadastre seu primeiro produto para começar a receber pedidos."
          action={
            <Button variant="primary" onClick={openNewModal}>
              Cadastrar produto
            </Button>
          }
        />
      )}

      {!loading && !error && products && products.length > 0 && (
        <Table columns={tableColumns} data={products} />
      )}

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingProduct ? 'Editar produto' : 'Novo produto'}
      >
        <form onSubmit={handleSave} className="space-y-4">
          <Input
            label="Nome do produto"
            placeholder="Ex: Pizza Margherita"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />

          <div className="w-full">
            <label htmlFor="prod-desc" className="block font-bold text-sm uppercase tracking-wider mb-1.5 text-brutal-black">
              Descrição do produto
            </label>
            <textarea
              id="prod-desc"
              rows={3}
              className="w-full border-4 border-brutal-black rounded-[1.5rem] px-5 py-3 text-lg bg-white text-brutal-black placeholder:text-black/40 focus:outline-none focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
              placeholder="Ingredientes, tamanho, detalhes..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Input
              label="Preço (R$)"
              placeholder="45,00"
              value={priceInput}
              onChange={(e) => setPriceInput(e.target.value)}
              required
            />
            {categories.length > 0 && (
              <Select
                label="Categoria"
                options={categories.map((c) => ({ value: c.id, label: c.name }))}
                value={categoryId}
                onChange={(val) => setCategoryId(val)}
              />
            )}
          </div>

          {modalError && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-red text-brutal-black font-bold rounded-[1.5rem]" role="alert">
              {modalError}
            </div>
          )}

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" type="submit" loading={saving}>
              Salvar produto
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Excluir produto?"
        message={`Deseja realmente remover o produto ${deleteTarget?.name}?`}
        confirmLabel="Excluir"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}

import { useEffect, useState } from 'react'
import {
  listSellerCategories,
  createSellerCategory,
  updateSellerCategory,
  deleteSellerCategory,
  reorderSellerCategories,
} from '../../services/sellerCatalog'
import type { SellerCategory } from '../../services/sellerCatalog'
import { unwrapError } from '../../services/api'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'

export default function CategoriesPage() {
  const [categories, setCategories] = useState<SellerCategory[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingCategory, setEditingCategory] = useState<SellerCategory | null>(null)
  const [name, setName] = useState('')
  const [saving, setSaving] = useState(false)
  const [modalError, setModalError] = useState<string | null>(null)

  const [deleteTarget, setDeleteTarget] = useState<SellerCategory | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    listSellerCategories()
      .then(setCategories)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const openNewModal = () => {
    setEditingCategory(null)
    setName('')
    setModalError(null)
    setModalOpen(true)
  }

  const openEditModal = (cat: SellerCategory) => {
    setEditingCategory(cat)
    setName(cat.name)
    setModalError(null)
    setModalOpen(true)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setModalError(null)

    try {
      if (editingCategory) {
        await updateSellerCategory(editingCategory.id, name)
      } else {
        await createSellerCategory(name)
      }
      setModalOpen(false)
      load()
    } catch (err) {
      const apiErr = unwrapError(err)
      setModalError(apiErr.message || 'Erro ao salvar categoria.')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    setDeleteError(null)

    try {
      await deleteSellerCategory(deleteTarget.id)
      setDeleteTarget(null)
      load()
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.code === 'category_in_use') {
        setDeleteError('Categoria possui produtos vinculados.')
      } else {
        setDeleteError(apiErr.message || 'Erro ao excluir categoria.')
      }
    } finally {
      setDeleting(false)
    }
  }

  const handleMove = async (index: number, direction: 'up' | 'down') => {
    if (!categories) return
    const targetIdx = direction === 'up' ? index - 1 : index + 1
    if (targetIdx < 0 || targetIdx >= categories.length) return

    const newArr = [...categories]
    const temp = newArr[index]
    newArr[index] = newArr[targetIdx]
    newArr[targetIdx] = temp

    setCategories(newArr)
    try {
      await reorderSellerCategories(newArr.map((c) => c.id))
    } catch {
      load()
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between flex-wrap gap-4 mb-6">
        <PageTitle title="Categorias" subtitle="Organize seu catálogo de produtos" />
        <Button variant="primary" onClick={openNewModal}>
          Nova categoria
        </Button>
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar categorias"
          message="Não foi possível exibir as categorias."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando categorias..." />}

      {!loading && !error && categories && categories.length === 0 && (
        <EmptyState
          title="Nenhuma categoria cadastrada"
          description="Crie categorias para agrupar seus produtos."
          action={
            <Button variant="primary" onClick={openNewModal}>
              Criar categoria
            </Button>
          }
        />
      )}

      {deleteError && (
        <div className="mb-6 p-4 border-4 border-brutal-black bg-brutal-red text-brutal-black font-bold rounded-[1.5rem]" role="alert">
          {deleteError}
        </div>
      )}

      {!loading && !error && categories && categories.length > 0 && (
        <div className="space-y-4 max-w-2xl">
          {categories.map((cat, idx) => (
            <div
              key={cat.id}
              className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex items-center justify-between gap-4"
            >
              <div className="flex items-center gap-3">
                <span className="font-mono text-sm font-bold text-black/40">#{idx + 1}</span>
                <h3 className="font-black italic text-xl text-brutal-black">{cat.name}</h3>
              </div>

              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={idx === 0}
                  onClick={() => handleMove(idx, 'up')}
                >
                  ↑
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={idx === categories.length - 1}
                  onClick={() => handleMove(idx, 'down')}
                >
                  ↓
                </Button>
                <Button variant="outline" size="sm" onClick={() => openEditModal(cat)}>
                  Editar
                </Button>
                <Button variant="danger" size="sm" onClick={() => setDeleteTarget(cat)}>
                  Excluir
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingCategory ? 'Editar categoria' : 'Nova categoria'}
      >
        <form onSubmit={handleSave} className="space-y-4">
          <Input
            label="Nome da categoria"
            placeholder="Ex: Pizzas, Bebidas, Sobremesas"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={modalError ?? undefined}
            required
          />

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" type="submit" loading={saving}>
              Salvar categoria
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Excluir categoria?"
        message={`Tem certeza que deseja excluir a categoria ${deleteTarget?.name}?`}
        confirmLabel="Excluir"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}

import { useEffect, useState } from 'react'
import {
  listCustomerAddresses,
  createCustomerAddress,
  updateCustomerAddress,
  deleteCustomerAddress,
  setDefaultCustomerAddress,
} from '../../services/customer'
import type { CustomerAddress, AddressPayload } from '../../types/customer'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'
import ConfirmDialog from '../../components/ui/ConfirmDialog'
import Badge from '../../components/ui/Badge'
import { unwrapError } from '../../services/api'

const emptyForm: AddressPayload = {
  street: '',
  number: '',
  complement: '',
  neighborhood: '',
  city: '',
  state: '',
  zip_code: '',
}

export default function AddressesPage() {
  const [addresses, setAddresses] = useState<CustomerAddress[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingAddress, setEditingAddress] = useState<CustomerAddress | null>(null)
  const [form, setForm] = useState<AddressPayload>(emptyForm)
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState(false)

  const [deleteTarget, setDeleteTarget] = useState<CustomerAddress | null>(null)
  const [deleting, setDeleting] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    listCustomerAddresses()
      .then(setAddresses)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const openNewModal = () => {
    setEditingAddress(null)
    setForm(emptyForm)
    setFieldErrors({})
    setModalOpen(true)
  }

  const openEditModal = (addr: CustomerAddress) => {
    setEditingAddress(addr)
    setForm({
      street: addr.street,
      number: addr.number,
      complement: addr.complement ?? '',
      neighborhood: addr.neighborhood,
      city: addr.city,
      state: addr.state,
      zip_code: addr.zip_code,
    })
    setFieldErrors({})
    setModalOpen(true)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setFieldErrors({})

    try {
      if (editingAddress) {
        await updateCustomerAddress(editingAddress.id, form)
      } else {
        await createCustomerAddress(form)
      }
      setModalOpen(false)
      load()
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.context && typeof apiErr.context === 'object') {
        setFieldErrors(apiErr.context as Record<string, string>)
      }
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await deleteCustomerAddress(deleteTarget.id)
      setDeleteTarget(null)
      load()
    } catch {
      // keep
    } finally {
      setDeleting(false)
    }
  }

  const handleSetDefault = async (id: string) => {
    try {
      await setDefaultCustomerAddress(id)
      load()
    } catch {
      // keep
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between flex-wrap gap-4 mb-6">
        <PageTitle title="Meus endereços" subtitle="Cadastre e gerencie seus locais de entrega" />
        <Button variant="primary" onClick={openNewModal}>
          Novo endereço
        </Button>
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar endereços"
          message="Não foi possível carregar sua lista de endereços."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando endereços..." />}

      {!loading && !error && addresses && addresses.length === 0 && (
        <EmptyState
          title="Nenhum endereço cadastrado"
          description="Adicione um endereço para poder fazer pedidos."
          action={
            <Button variant="primary" onClick={openNewModal}>
              Cadastrar endereço
            </Button>
          }
        />
      )}

      {!loading && !error && addresses && addresses.length > 0 && (
        <div className="grid md:grid-cols-2 gap-6">
          {addresses.map((addr) => (
            <div
              key={addr.id}
              className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between gap-2 mb-3">
                  <h3 className="font-black italic text-xl text-brutal-black">
                    {addr.street}, {addr.number}
                  </h3>
                  {addr.default && <Badge status="approved" label="Padrão" />}
                </div>

                {addr.complement && <p className="text-black/60 text-sm mb-1">{addr.complement}</p>}

                <p className="text-black/70 text-sm font-bold">
                  {addr.neighborhood} — {addr.city}/{addr.state}
                </p>
                <p className="text-black/50 text-xs font-mono mt-1">CEP: {addr.zip_code}</p>
              </div>

              <div className="flex flex-wrap items-center gap-2 mt-6 pt-4 border-t-2 border-black/10">
                {!addr.default && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleSetDefault(addr.id)}
                  >
                    Tornar padrão
                  </Button>
                )}
                <Button variant="outline" size="sm" onClick={() => openEditModal(addr)}>
                  Editar
                </Button>
                {!addr.default && (
                  <Button
                    variant="danger"
                    size="sm"
                    onClick={() => setDeleteTarget(addr)}
                  >
                    Excluir
                  </Button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal de Formulário */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingAddress ? 'Editar endereço' : 'Novo endereço'}
      >
        <form onSubmit={handleSave} className="space-y-4">
          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2">
              <Input
                label="Rua / Logradouro"
                value={form.street}
                onChange={(e) => setForm({ ...form, street: e.target.value })}
                error={fieldErrors.street}
                required
              />
            </div>
            <div>
              <Input
                label="Número"
                value={form.number}
                onChange={(e) => setForm({ ...form, number: e.target.value })}
                error={fieldErrors.number}
                required
              />
            </div>
          </div>

          <Input
            label="Complemento (opcional)"
            value={form.complement ?? ''}
            onChange={(e) => setForm({ ...form, complement: e.target.value })}
            error={fieldErrors.complement}
          />

          <div className="grid grid-cols-2 gap-3">
            <Input
              label="Bairro"
              value={form.neighborhood}
              onChange={(e) => setForm({ ...form, neighborhood: e.target.value })}
              error={fieldErrors.neighborhood}
              required
            />
            <Input
              label="CEP"
              value={form.zip_code}
              onChange={(e) => setForm({ ...form, zip_code: e.target.value })}
              error={fieldErrors.zip_code}
              required
            />
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2">
              <Input
                label="Cidade"
                value={form.city}
                onChange={(e) => setForm({ ...form, city: e.target.value })}
                error={fieldErrors.city}
                required
              />
            </div>
            <div>
              <Input
                label="Estado (UF)"
                value={form.state}
                onChange={(e) => setForm({ ...form, state: e.target.value })}
                error={fieldErrors.state}
                required
              />
            </div>
          </div>

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" type="submit" loading={saving}>
              Salvar endereço
            </Button>
          </div>
        </form>
      </Modal>

      {/* ConfirmDialog de exclusão */}
      <ConfirmDialog
        open={deleteTarget !== null}
        title="Excluir endereço?"
        message={`Deseja realmente remover o endereço ${deleteTarget?.street}, ${deleteTarget?.number}?`}
        confirmLabel="Excluir"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}

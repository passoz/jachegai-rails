import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { getCustomerCart, checkoutCustomerCart } from '../../services/customerCart'
import { listCustomerAddresses, createCustomerAddress } from '../../services/customer'
import type { CustomerCart } from '../../services/customerCart'
import type { CustomerAddress, AddressPayload } from '../../types/customer'
import { formatMoney } from '../../lib/money'
import { unwrapError } from '../../services/api'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import Select from '../../components/ui/Select'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'

const emptyForm: AddressPayload = {
  street: '',
  number: '',
  complement: '',
  neighborhood: '',
  city: '',
  state: '',
  zip_code: '',
}

export default function CheckoutPage() {
  const [cart, setCart] = useState<CustomerCart | null>(null)
  const [addresses, setAddresses] = useState<CustomerAddress[] | null>(null)
  const [selectedAddressId, setSelectedAddressId] = useState<string>('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [submitting, setSubmitting] = useState(false)
  const [checkoutError, setCheckoutError] = useState<string | null>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState<AddressPayload>(emptyForm)
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
  const [savingAddress, setSavingAddress] = useState(false)

  const navigate = useNavigate()

  const load = async () => {
    setLoading(true)
    setError(false)
    try {
      const [cartRes, addrRes] = await Promise.all([
        getCustomerCart(),
        listCustomerAddresses(),
      ])
      setCart(cartRes)
      setAddresses(addrRes)

      const defaultAddr = addrRes.find((a) => a.default) ?? addrRes[0]
      if (defaultAddr) {
        setSelectedAddressId(defaultAddr.id)
      }
    } catch {
      setError(true)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const handleCheckout = async () => {
    if (!selectedAddressId) {
      setCheckoutError('Selecione um endereço para entrega.')
      return
    }

    setSubmitting(true)
    setCheckoutError(null)

    try {
      const result = await checkoutCustomerCart(selectedAddressId)
      navigate(`/customer/orders/${result.id}`)
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.code === 'insufficient_inventory') {
        setCheckoutError('Estoque insuficiente para um ou mais itens.')
      } else if (apiErr.code === 'idempotency_conflict') {
        setCheckoutError('Este pedido já foi processado.')
      } else if (apiErr.code === 'external_dependency_unavailable') {
        setCheckoutError('Erro no processamento do pagamento. Tente novamente.')
      } else {
        setCheckoutError(apiErr.message || 'Falha ao finalizar pedido.')
      }
    } finally {
      setSubmitting(false)
    }
  }

  const handleCreateAddress = async (e: React.FormEvent) => {
    e.preventDefault()
    setSavingAddress(true)
    setFieldErrors({})

    try {
      const created = await createCustomerAddress(form)
      const updatedAddrs = await listCustomerAddresses()
      setAddresses(updatedAddrs)
      setSelectedAddressId(created.id)
      setModalOpen(false)
    } catch (err) {
      const apiErr = unwrapError(err)
      if (apiErr.context && typeof apiErr.context === 'object') {
        setFieldErrors(apiErr.context as Record<string, string>)
      }
    } finally {
      setSavingAddress(false)
    }
  }

  const addressOptions =
    addresses?.map((a) => ({
      value: a.id,
      label: `${a.street}, ${a.number} — ${a.neighborhood} (${a.city}/${a.state})${
        a.default ? ' [Padrão]' : ''
      }`,
    })) ?? []

  return (
    <div>
      <PageTitle title="Checkout" subtitle="Confirme o endereço e finalize seu pedido" />

      {error && (
        <ErrorState
          title="Erro ao carregar dados"
          message="Não foi possível carregar as informações do pedido."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando checkout..." />}

      {!loading && !error && cart && cart.items.length === 0 && (
        <EmptyState
          title="Seu carrinho está vazio"
          description="Você precisa adicionar produtos ao carrinho antes de fazer o checkout."
          action={
            <Link to="/sellers">
              <Button variant="primary">Explorar sellers</Button>
            </Link>
          }
        />
      )}

      {!loading && !error && cart && cart.items.length > 0 && (
        <div className="grid lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-6">
            {/* Seletor de endereço */}
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <div className="flex items-center justify-between flex-wrap gap-2">
                <h3 className="font-black italic text-2xl text-brutal-black">Endereço de entrega</h3>
                <button
                  type="button"
                  onClick={() => {
                    setForm(emptyForm)
                    setFieldErrors({})
                    setModalOpen(true)
                  }}
                  className="font-bold text-sm text-brutal-red underline hover:text-black"
                >
                  + Adicionar endereço
                </button>
              </div>

              {addressOptions.length > 0 ? (
                <Select
                  label="Selecione o local de entrega"
                  options={addressOptions}
                  value={selectedAddressId}
                  onChange={(val) => setSelectedAddressId(val)}
                />
              ) : (
                <div className="p-4 border-2 border-brutal-black rounded-[1rem] bg-brutal-gray text-center">
                  <p className="font-bold mb-2">Nenhum endereço cadastrado.</p>
                  <Button variant="primary" size="sm" onClick={() => setModalOpen(true)}>
                    Cadastrar endereço
                  </Button>
                </div>
              )}
            </div>

            {/* Resumo dos itens */}
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Itens do pedido
              </h3>

              <div className="divide-y-2 divide-black/10">
                {cart.items.map((item) => (
                  <div key={item.id} className="py-3 flex justify-between items-center">
                    <div>
                      <p className="font-black italic text-lg text-brutal-black">{item.name}</p>
                      <p className="text-sm font-bold text-black/60">
                        {item.quantity}x {formatMoney(item.price_cents, item.currency)}
                      </p>
                    </div>
                    <p className="font-black italic text-lg text-brutal-black">
                      {formatMoney(item.price_cents * item.quantity, item.currency)}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div>
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
              <h3 className="font-black italic text-2xl text-brutal-black border-b-4 border-brutal-black pb-3">
                Totais
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

              {checkoutError && (
                <div className="p-4 border-4 border-brutal-black bg-brutal-red text-brutal-black font-bold rounded-[1.5rem]" role="alert">
                  {checkoutError}
                </div>
              )}

              <Button
                variant="primary"
                className="w-full text-lg mt-4"
                loading={submitting}
                disabled={!selectedAddressId}
                onClick={handleCheckout}
              >
                Confirmar pedido
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Modal para novo endereço rápido */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Novo endereço de entrega"
      >
        <form onSubmit={handleCreateAddress} className="space-y-4">
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
            <Button variant="primary" type="submit" loading={savingAddress}>
              Salvar endereço
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listAdminInvoices, generateAdminInvoice } from '../../services/adminSystem'
import { listAdminSellers } from '../../services/adminModeration'
import type { AdminInvoice } from '../../services/adminSystem'
import type { SellerProfile } from '../../services/seller'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function InvoicesPage() {
  const [invoices, setInvoices] = useState<AdminInvoice[] | null>(null)
  const [sellers, setSellers] = useState<SellerProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [modalOpen, setModalOpen] = useState(false)
  const [sellerId, setSellerId] = useState('')
  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [generating, setGenerating] = useState(false)
  const [modalError, setModalError] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    Promise.all([listAdminInvoices(), listAdminSellers()])
      .then(([invs, slls]) => {
        setInvoices(invs)
        setSellers(slls)
        if (slls.length > 0) setSellerId(slls[0].id)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!sellerId || !periodStart || !periodEnd) return
    setGenerating(true)
    setModalError(null)

    try {
      await generateAdminInvoice({
        seller_id: sellerId,
        period_start: periodStart,
        period_end: periodEnd,
      })
      setModalOpen(false)
      load()
    } catch {
      setModalError('Erro ao gerar fatura para o período informado.')
    } finally {
      setGenerating(false)
    }
  }

  const tableColumns = [
    {
      key: 'id',
      header: 'ID da Fatura',
      render: (i: AdminInvoice) => (
        <Link to={`/admin/invoices/${i.id}`} className="font-mono text-sm font-bold text-brutal-black hover:underline">
          #{i.id.slice(0, 8)}
        </Link>
      ),
    },
    {
      key: 'seller',
      header: 'Seller',
      render: (i: AdminInvoice) => <span className="font-black italic">{i.seller_name ?? i.seller_id}</span>,
    },
    {
      key: 'amount',
      header: 'Valor Total',
      render: (i: AdminInvoice) => (
        <span className="font-black italic text-brutal-red">
          {formatMoney(i.amount_cents, i.currency)}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Ações',
      render: (i: AdminInvoice) => (
        <Link to={`/admin/invoices/${i.id}`} className="font-bold text-sm text-brutal-red hover:underline">
          Detalhes →
        </Link>
      ),
    },
  ]

  return (
    <div>
      <div className="flex items-center justify-between flex-wrap gap-4 mb-6">
        <PageTitle title="Faturas dos Sellers" subtitle="Gere e consulte faturas financeiras de repasse" />
        <Button variant="primary" onClick={() => setModalOpen(true)}>
          Gerar fatura
        </Button>
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar faturas"
          message="Não foi possível exibir a lista de faturas."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando faturas..." />}

      {!loading && !error && invoices && (
        <Table columns={tableColumns} data={invoices} emptyMessage="Nenhuma fatura gerada até o momento." />
      )}

      {/* Modal de Gerar Fatura */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Gerar nova fatura">
        <form onSubmit={handleGenerate} className="space-y-4">
          {sellers.length > 0 && (
            <Select
              label="Selecione o Seller"
              options={sellers.map((s) => ({ value: s.id, label: s.name }))}
              value={sellerId}
              onChange={(val) => setSellerId(val)}
            />
          )}

          <Input
            label="Início do período"
            type="date"
            value={periodStart}
            onChange={(e) => setPeriodStart(e.target.value)}
            required
          />

          <Input
            label="Fim do período"
            type="date"
            value={periodEnd}
            onChange={(e) => setPeriodEnd(e.target.value)}
            required
          />

          {modalError && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-red text-brutal-black font-bold rounded-[1.5rem]" role="alert">
              {modalError}
            </div>
          )}

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" type="submit" loading={generating}>
              Gerar
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

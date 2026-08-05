import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getAdminInvoice } from '../../services/adminSystem'
import type { AdminInvoice } from '../../services/adminSystem'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function InvoiceDetailPage() {
  const { id = '' } = useParams()
  const [invoice, setInvoice] = useState<AdminInvoice | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminInvoice(id)
      .then(setInvoice)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  return (
    <div>
      <Link to="/admin/invoices" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para lista de faturas
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar fatura"
          message="Não foi possível buscar as informações da fatura."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando fatura..." />}

      {!loading && !error && invoice && (
        <div className="max-w-2xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="border-b-4 border-brutal-black pb-4">
            <PageTitle title={`Fatura #${invoice.id.slice(0, 8)}`} subtitle={`Seller: ${invoice.seller_name ?? invoice.seller_id}`} />
            <p className="text-xs font-mono text-black/40">ID completo: {invoice.id}</p>
          </div>

          <div className="space-y-4">
            {invoice.period_start && invoice.period_end && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Período de Apuração</p>
                <p className="font-bold text-base">
                  {new Date(invoice.period_start).toLocaleDateString('pt-BR')} até{' '}
                  {new Date(invoice.period_end).toLocaleDateString('pt-BR')}
                </p>
              </div>
            )}

            <div>
              <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Valor Total da Fatura</p>
              <p className="font-black italic text-4xl text-brutal-red">
                {formatMoney(invoice.amount_cents, invoice.currency)}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

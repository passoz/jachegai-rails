import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getAdminPayment, confirmAdminPayment } from '../../services/adminOps'
import type { AdminPayment } from '../../services/adminOps'
import { formatMoney } from '../../lib/money'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function PaymentDetailPage() {
  const { id = '' } = useParams()
  const [payment, setPayment] = useState<AdminPayment | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [confirming, setConfirming] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminPayment(id)
      .then(setPayment)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleConfirm = async () => {
    setConfirming(true)
    setFeedback(null)
    try {
      const updated = await confirmAdminPayment(id)
      setPayment(updated)
      setFeedback('Pagamento confirmado manualmente com sucesso!')
    } catch {
      setFeedback('Erro ao confirmar pagamento.')
    } finally {
      setConfirming(false)
    }
  }

  return (
    <div>
      <Link to="/admin/payments" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para lista de pagamentos
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar pagamento"
          message="Não foi possível buscar as informações da transação."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando transação..." />}

      {!loading && !error && payment && (
        <div className="max-w-2xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-6">
          <div className="flex items-center justify-between flex-wrap gap-4 border-b-4 border-brutal-black pb-4">
            <div>
              <PageTitle title={`Pagamento #${payment.id.slice(0, 8)}`} subtitle={`Pedido: #${payment.order_id.slice(0, 8)}`} />
              <p className="text-xs font-mono text-black/40">ID completo: {payment.id}</p>
            </div>
            <Badge status={payment.status} />
          </div>

          <div className="space-y-4">
            <div>
              <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Valor da transação</p>
              <p className="font-black italic text-4xl text-brutal-red">
                {formatMoney(payment.amount_cents, payment.currency)}
              </p>
            </div>

            {payment.created_at && (
              <div>
                <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Data de registro</p>
                <p className="font-bold text-base">{new Date(payment.created_at).toLocaleString('pt-BR')}</p>
              </div>
            )}
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          {payment.status === 'pending' && (
            <div className="pt-4 border-t-4 border-brutal-black">
              <Button variant="primary" loading={confirming} onClick={handleConfirm} className="w-full">
                Confirmar pagamento (Marcar como Pago)
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

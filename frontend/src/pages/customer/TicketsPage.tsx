import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listCustomerTickets, createCustomerTicket } from '../../services/customerOrders'
import type { CustomerTicket } from '../../services/customerOrders'
import PageTitle from '../../components/ui/PageTitle'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'
import EmptyState from '../../components/ui/EmptyState'
import Badge from '../../components/ui/Badge'

export default function TicketsPage() {
  const [tickets, setTickets] = useState<CustomerTicket[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [modalOpen, setModalOpen] = useState(false)
  const [subject, setSubject] = useState('')
  const [message, setMessage] = useState('')
  const [orderId, setOrderId] = useState('')
  const [creating, setCreating] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    listCustomerTickets()
      .then(setTickets)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    setCreating(true)
    try {
      await createCustomerTicket(subject, message, orderId || undefined)
      setModalOpen(false)
      setSubject('')
      setMessage('')
      setOrderId('')
      load()
    } catch {
      // keep
    } finally {
      setCreating(false)
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between flex-wrap gap-4 mb-6">
        <PageTitle title="Suporte e Tickets" subtitle="Abra chamados para ajuda e suporte no pedido" />
        <Button variant="primary" onClick={() => setModalOpen(true)}>
          Novo ticket
        </Button>
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar tickets"
          message="Não foi possível listar seus chamados de suporte."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando tickets..." />}

      {!loading && !error && tickets && tickets.length === 0 && (
        <EmptyState
          title="Nenhum ticket aberto"
          description="Você ainda não abriu nenhum chamado de suporte."
          action={
            <Button variant="primary" onClick={() => setModalOpen(true)}>
              Abrir primeiro ticket
            </Button>
          }
        />
      )}

      {!loading && !error && tickets && tickets.length > 0 && (
        <div className="space-y-4">
          {tickets.map((t) => (
            <Link
              key={t.id}
              to={`/customer/tickets/${t.id}`}
              className="block border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5 transition-all"
            >
              <div className="flex items-center justify-between flex-wrap gap-4">
                <div>
                  <h3 className="font-black italic text-xl text-brutal-black">{t.subject}</h3>
                  <p className="text-sm font-bold text-black/50 mt-1">
                    Aberto em {new Date(t.created_at).toLocaleDateString('pt-BR')}
                  </p>
                </div>

                <Badge status={t.status} />
              </div>
            </Link>
          ))}
        </div>
      )}

      {/* Modal para novo ticket */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Novo ticket de suporte"
      >
        <form onSubmit={handleCreate} className="space-y-4">
          <Input
            label="Assunto"
            placeholder="Descreva o motivo do chamado"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            required
          />

          <div className="w-full">
            <label htmlFor="ticket-message" className="block font-bold text-sm uppercase tracking-wider mb-1.5 text-brutal-black">
              Mensagem
            </label>
            <textarea
              id="ticket-message"
              rows={4}
              className="w-full border-4 border-brutal-black rounded-[1.5rem] px-5 py-3 text-lg bg-white text-brutal-black placeholder:text-black/40 focus:outline-none focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
              placeholder="Descreva os detalhes da sua solicitação..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              required
            />
          </div>

          <Input
            label="Código do Pedido (opcional)"
            placeholder="ID do pedido relacionado"
            value={orderId}
            onChange={(e) => setOrderId(e.target.value)}
          />

          <div className="flex gap-3 justify-end mt-6">
            <Button variant="outline" type="button" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" type="submit" loading={creating}>
              Abrir ticket
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

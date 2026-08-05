import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  getAdminTicket,
  addAdminTicketMessage,
  transitionAdminTicket,
} from '../../services/adminOps'
import type { CustomerTicket, TicketMessage } from '../../services/customerOrders'
import PageTitle from '../../components/ui/PageTitle'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function TicketDetailPage() {
  const { id = '' } = useParams()
  const [ticket, setTicket] = useState<CustomerTicket | null>(null)
  const [messages, setMessages] = useState<TicketMessage[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [newMessage, setNewMessage] = useState('')
  const [sending, setSending] = useState(false)
  const [transitioning, setTransitioning] = useState(false)
  const [feedback, setFeedback] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    getAdminTicket(id)
      .then((data) => {
        setTicket(data)
        setMessages(data.messages ?? [])
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const handleTransition = async (action: 'start_progress' | 'resolve' | 'reopen' | 'close') => {
    setTransitioning(true)
    setFeedback(null)
    try {
      const updated = await transitionAdminTicket(id, action)
      setTicket(updated)
      setFeedback(`Status do ticket alterado para ${updated.status}.`)
    } catch {
      setFeedback('Erro ao alterar status do ticket.')
    } finally {
      setTransitioning(false)
    }
  }

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newMessage.trim()) return
    setSending(true)
    try {
      const added = await addAdminTicketMessage(id, newMessage.trim())
      setMessages((prev) => [...prev, added])
      setNewMessage('')
    } catch {
      // keep
    } finally {
      setSending(false)
    }
  }

  return (
    <div>
      <Link to="/admin/tickets" className="font-bold text-brutal-red hover:underline mb-4 inline-block">
        ← Voltar para lista de tickets
      </Link>

      {error && (
        <ErrorState
          title="Erro ao carregar ticket"
          message="Não foi possível exibir as informações deste chamado."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando conversa..." />}

      {!loading && !error && ticket && (
        <div className="max-w-3xl space-y-6">
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex items-start justify-between flex-wrap gap-4">
            <div>
              <PageTitle title={ticket.subject} subtitle={`Ticket #${ticket.id}`} />
              <p className="text-sm font-bold text-black/50">
                Aberto em {new Date(ticket.created_at).toLocaleString('pt-BR')}
              </p>
            </div>

            <div className="flex flex-col items-end gap-3">
              <Badge status={ticket.status} />

              <div className="flex flex-wrap gap-2">
                {ticket.status === 'open' && (
                  <>
                    <Button variant="primary" size="sm" loading={transitioning} onClick={() => handleTransition('start_progress')}>
                      Iniciar atendimento
                    </Button>
                    <Button variant="outline" size="sm" loading={transitioning} onClick={() => handleTransition('resolve')}>
                      Resolver
                    </Button>
                  </>
                )}
                {ticket.status === 'in_progress' && (
                  <Button variant="primary" size="sm" loading={transitioning} onClick={() => handleTransition('resolve')}>
                    Resolver
                  </Button>
                )}
                {ticket.status === 'resolved' && (
                  <>
                    <Button variant="outline" size="sm" loading={transitioning} onClick={() => handleTransition('reopen')}>
                      Reabrir
                    </Button>
                    <Button variant="danger" size="sm" loading={transitioning} onClick={() => handleTransition('close')}>
                      Fechar
                    </Button>
                  </>
                )}
              </div>
            </div>
          </div>

          {feedback && (
            <div className="p-4 border-4 border-brutal-black bg-brutal-gray font-bold rounded-[1.5rem]" role="status">
              {feedback}
            </div>
          )}

          {/* Chat Timeline */}
          <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] space-y-4">
            <h3 className="font-black italic text-xl text-brutal-black border-b-4 border-brutal-black pb-3">
              Histórico de mensagens
            </h3>

            <div className="space-y-4 my-4 max-h-[400px] overflow-y-auto p-2">
              {messages.map((msg) => {
                const isAdmin = msg.sender === 'admin' || msg.sender === 'system'
                return (
                  <div
                    key={msg.id}
                    className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                  >
                    <div
                      className={`max-w-[80%] border-4 border-brutal-black rounded-[1.5rem] p-4 font-medium text-base shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] ${
                        isAdmin
                          ? 'bg-brutal-black text-white rounded-br-none'
                          : 'bg-white text-brutal-black rounded-bl-none'
                      }`}
                    >
                      <p className={`font-bold text-xs uppercase tracking-wider mb-1 ${isAdmin ? 'text-white/70' : 'text-black/60'}`}>
                        {isAdmin ? 'Suporte JaChegai (Admin)' : 'Cliente'}
                      </p>
                      <p className="whitespace-pre-wrap">{msg.body}</p>
                      <p className={`text-[10px] font-bold mt-2 text-right ${isAdmin ? 'text-white/50' : 'text-black/40'}`}>
                        {new Date(msg.created_at).toLocaleTimeString('pt-BR')}
                      </p>
                    </div>
                  </div>
                )
              })}
            </div>

            {ticket.status !== 'closed' && (
              <form onSubmit={handleSendMessage} className="space-y-3 pt-4 border-t-4 border-brutal-black">
                <textarea
                  rows={3}
                  className="w-full border-4 border-brutal-black rounded-[1.5rem] px-5 py-3 text-lg bg-white text-brutal-black placeholder:text-black/40 focus:outline-none focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
                  placeholder="Digite sua mensagem como suporte..."
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  required
                />
                <div className="flex justify-end">
                  <Button type="submit" variant="primary" loading={sending}>
                    Enviar resposta
                  </Button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

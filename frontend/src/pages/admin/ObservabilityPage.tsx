import { useEffect, useState } from 'react'
import {
  getObservabilitySummary,
  getObservabilityRequests,
} from '../../services/adminSystem'
import type { ObservabilitySummary, ObservabilityRequest } from '../../services/adminSystem'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

export default function ObservabilityPage() {
  const [summary, setSummary] = useState<ObservabilitySummary | null>(null)
  const [requests, setRequests] = useState<ObservabilityRequest[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    Promise.all([getObservabilitySummary(), getObservabilityRequests()])
      .then(([sum, reqs]) => {
        setSummary(sum)
        setRequests(reqs)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const tableColumns = [
    { key: 'method', header: 'Método', render: (r: ObservabilityRequest) => <span className="font-bold uppercase">{r.method}</span> },
    { key: 'path', header: 'Caminho (Path)', render: (r: ObservabilityRequest) => <span className="font-mono text-sm">{r.path}</span> },
    {
      key: 'status',
      header: 'Status Code',
      render: (r: ObservabilityRequest) => (
        <span
          className={`font-mono font-bold px-2 py-1 border-2 border-brutal-black rounded-lg ${
            r.status >= 500
              ? 'bg-brutal-red text-white'
              : r.status >= 400
              ? 'bg-brutal-gray text-black'
              : 'bg-white text-black'
          }`}
        >
          {r.status}
        </span>
      ),
    },
    { key: 'duration', header: 'Duração', render: (r: ObservabilityRequest) => <span className="font-mono text-sm">{r.duration_ms} ms</span> },
  ]

  return (
    <div>
      <PageTitle title="Observabilidade do Sistema" subtitle="Saúde técnica, logs de requisição e background jobs" />

      {error && (
        <ErrorState
          title="Erro ao carregar observabilidade"
          message="Não foi possível buscar as estatísticas do servidor."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando métricas..." />}

      {!loading && !error && summary && (
        <div className="space-y-8">
          <div className="grid md:grid-cols-3 gap-6 max-w-4xl">
            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
              <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Total de Requests</p>
              <p className="font-black italic text-4xl text-brutal-black">
                {(summary.requests_count as number) ?? 0}
              </p>
            </div>

            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
              <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Pedidos Pendentes</p>
              <p className="font-black italic text-4xl text-brutal-red">
                {(summary.pending_orders_count as number) ?? 0}
              </p>
            </div>

            <div className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
              <p className="text-sm font-bold text-black/50 uppercase tracking-wider mb-1">Outbox Jobs</p>
              <p className="font-black italic text-4xl text-brutal-black">
                {(summary.outbox_jobs_count as number) ?? 0}
              </p>
            </div>
          </div>

          <div>
            <h3 className="font-black italic text-2xl text-brutal-black mb-4">Requisições Recentes</h3>
            {requests && requests.length > 0 ? (
              <Table columns={tableColumns} data={requests} />
            ) : (
              <div className="p-6 border-4 border-brutal-black rounded-[1.5rem] bg-white text-center font-bold text-black/50">
                Nenhuma requisição registrada no log recente.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

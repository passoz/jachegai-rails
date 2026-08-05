import { useEffect, useState } from 'react'
import { listAdminSettings, createAdminSetting } from '../../services/adminSystem'
import type { AdminSetting } from '../../services/adminSystem'
import PageTitle from '../../components/ui/PageTitle'
import Table from '../../components/ui/Table'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import LoadingSpinner from '../../components/ui/LoadingSpinner'
import ErrorState from '../../components/ui/ErrorState'

const settingOptions = [
  { value: 'marketplace_fee_percent', label: 'marketplace_fee_percent (Taxa da plataforma %)' },
  { value: 'min_order_cents', label: 'min_order_cents (Pedido mínimo em centavos)' },
  { value: 'courier_base_fee_cents', label: 'courier_base_fee_cents (Taxa base do courier em centavos)' },
]

export default function SettingsPage() {
  const [settings, setSettings] = useState<AdminSetting[] | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const [modalOpen, setModalOpen] = useState(false)
  const [key, setKey] = useState('marketplace_fee_percent')
  const [value, setValue] = useState('')
  const [effectiveFrom, setEffectiveFrom] = useState('')
  const [saving, setSaving] = useState(false)
  const [modalError, setModalError] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    setError(false)
    listAdminSettings()
      .then(setSettings)
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!key || !value) return
    setSaving(true)
    setModalError(null)

    try {
      await createAdminSetting({
        key,
        value,
        effective_from: effectiveFrom || undefined,
      })
      setModalOpen(false)
      setValue('')
      setEffectiveFrom('')
      load()
    } catch {
      setModalError('Erro ao criar configuração do sistema.')
    } finally {
      setSaving(false)
    }
  }

  const tableColumns = [
    {
      key: 'key',
      header: 'Chave da Configuração',
      render: (s: AdminSetting) => <span className="font-mono font-bold text-lg">{s.key}</span>,
    },
    {
      key: 'value',
      header: 'Valor Vigente',
      render: (s: AdminSetting) => (
        <span className="font-black italic text-xl text-brutal-red">{s.value}</span>
      ),
    },
    {
      key: 'effective_from',
      header: 'Vigência A Partir De',
      render: (s: AdminSetting) => (
        <span className="text-xs font-bold text-black/60">
          {s.effective_from ? new Date(s.effective_from).toLocaleDateString('pt-BR') : 'Imediata'}
        </span>
      ),
    },
  ]

  return (
    <div>
      <div className="flex items-center justify-between flex-wrap gap-4 mb-6">
        <PageTitle title="Configurações do Sistema" subtitle="Parâmetros globais do marketplace e taxas" />
        <Button variant="primary" onClick={() => setModalOpen(true)}>
          Nova configuração
        </Button>
      </div>

      {error && (
        <ErrorState
          title="Erro ao carregar configurações"
          message="Não foi possível exibir a lista de parâmetros do sistema."
          onRetry={load}
        />
      )}

      {loading && <LoadingSpinner label="Carregando configurações..." />}

      {!loading && !error && settings && (
        <Table columns={tableColumns} data={settings} emptyMessage="Nenhuma configuração cadastrada." />
      )}

      {/* Modal de Nova Configuração */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Adicionar configuração">
        <form onSubmit={handleSave} className="space-y-4">
          <Select
            label="Chave da configuração"
            options={settingOptions}
            value={key}
            onChange={(val) => setKey(val)}
          />

          <Input
            label="Valor"
            placeholder="Ex: 10 para 10% ou 500 para R$ 5,00 em centavos"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            required
          />

          <Input
            label="Vigência a partir de (opcional)"
            type="date"
            value={effectiveFrom}
            onChange={(e) => setEffectiveFrom(e.target.value)}
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
            <Button variant="primary" type="submit" loading={saving}>
              Salvar
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

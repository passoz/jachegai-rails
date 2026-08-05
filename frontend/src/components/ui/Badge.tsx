const badgeVariants: Record<string, string> = {
  // Order states
  pending: 'bg-yellow-100 text-black',
  accepted: 'bg-green-100 text-black',
  rejected: 'bg-brutal-red text-black',
  preparing: 'bg-blue-100 text-black',
  ready: 'bg-teal-100 text-black',
  assigned: 'bg-indigo-100 text-black',
  picked_up: 'bg-purple-100 text-black',
  delivered: 'bg-green-100 text-black',
  cancelled: 'bg-brutal-red text-black',
  // Moderation states
  pending_review: 'bg-yellow-100 text-black',
  approved: 'bg-green-100 text-black',
  suspended: 'bg-orange-100 text-black',
  // Payment states
  paid: 'bg-green-100 text-black',
  failed: 'bg-brutal-red text-black',
  refunded: 'bg-gray-200 text-black',
  // Courier operational
  available: 'bg-green-100 text-black',
  offline: 'bg-gray-200 text-black',
  on_delivery: 'bg-blue-100 text-black',
  // Ticket states
  open: 'bg-yellow-100 text-black',
  in_progress: 'bg-blue-100 text-black',
  resolved: 'bg-green-100 text-black',
  closed: 'bg-gray-200 text-black',
  // Product
  active: 'bg-green-100 text-black',
  inactive: 'bg-gray-200 text-black',
}

const defaultLabels: Record<string, string> = {
  pending: 'Pendente',
  accepted: 'Aceito',
  rejected: 'Rejeitado',
  preparing: 'Em preparo',
  ready: 'Pronto',
  assigned: 'Em entrega',
  picked_up: 'Coletado',
  delivered: 'Entregue',
  cancelled: 'Cancelado',
  pending_review: 'Aguardando análise',
  approved: 'Aprovado',
  suspended: 'Suspenso',
  paid: 'Pago',
  failed: 'Falhou',
  refunded: 'Estornado',
  available: 'Disponível',
  offline: 'Offline',
  on_delivery: 'Em entrega',
  open: 'Aberto',
  in_progress: 'Em atendimento',
  resolved: 'Resolvido',
  closed: 'Fechado',
  active: 'Ativo',
  inactive: 'Inativo',
}

interface BadgeProps {
  status: string
  label?: string
}

export default function Badge({ status, label }: BadgeProps) {
  const variant = badgeVariants[status] ?? 'bg-gray-200 text-black'
  const text = label ?? defaultLabels[status] ?? status

  return (
    <span
      className={[
        'inline-block border-2 border-brutal-black rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wide',
        variant,
      ].join(' ')}
    >
      {text}
    </span>
  )
}

const badgeVariants: Record<string, string> = {
  // Positive / Active / Success states -> White with black text & black border
  accepted: 'bg-white text-brutal-black',
  ready: 'bg-white text-brutal-black',
  delivered: 'bg-white text-brutal-black',
  approved: 'bg-white text-brutal-black',
  paid: 'bg-white text-brutal-black',
  available: 'bg-white text-brutal-black',
  resolved: 'bg-white text-brutal-black',
  active: 'bg-white text-brutal-black',

  // Negative / Danger / Warning states -> Brutal Red with black text
  rejected: 'bg-brutal-red text-brutal-black',
  cancelled: 'bg-brutal-red text-brutal-black',
  suspended: 'bg-brutal-red text-brutal-black',
  failed: 'bg-brutal-red text-brutal-black',

  // Pending / Neutral states -> Brutal Gray with black text
  pending: 'bg-brutal-gray text-brutal-black',
  preparing: 'bg-brutal-gray text-brutal-black',
  assigned: 'bg-brutal-gray text-brutal-black',
  picked_up: 'bg-brutal-gray text-brutal-black',
  pending_review: 'bg-brutal-gray text-brutal-black',
  refunded: 'bg-brutal-gray text-brutal-black',
  offline: 'bg-brutal-gray text-brutal-black',
  on_delivery: 'bg-brutal-gray text-brutal-black',
  open: 'bg-brutal-gray text-brutal-black',
  in_progress: 'bg-brutal-gray text-brutal-black',
  closed: 'bg-brutal-gray text-brutal-black',
  inactive: 'bg-brutal-gray text-brutal-black',
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
  const variant = badgeVariants[status] ?? 'bg-brutal-gray text-brutal-black'
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

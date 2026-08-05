import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import Badge from './Badge'

describe('Badge', () => {
  it('renders default label for known status', () => {
    render(<Badge status="pending" />)
    expect(screen.getByText('Pendente')).toBeInTheDocument()
  })

  it('renders custom label when provided', () => {
    render(<Badge status="pending" label="Aguardando" />)
    expect(screen.getByText('Aguardando')).toBeInTheDocument()
  })

  it('renders status text when status is unknown', () => {
    render(<Badge status="weird_status" />)
    expect(screen.getByText('weird_status')).toBeInTheDocument()
  })

  it('renders all status labels', () => {
    const cases: Record<string, string> = {
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
      open: 'Aberto',
      in_progress: 'Em atendimento',
      resolved: 'Resolvido',
      closed: 'Fechado',
      active: 'Ativo',
      inactive: 'Inativo',
    }
    Object.entries(cases).forEach(([status, label]) => {
      const { unmount } = render(<Badge status={status} />)
      expect(screen.getByText(label)).toBeInTheDocument()
      unmount()
    })
  })

  it('applies border classes', () => {
    render(<Badge status="pending" />)
    expect(screen.getByText('Pendente').className).toContain('border-2')
    expect(screen.getByText('Pendente').className).toContain('border-brutal-black')
  })
})

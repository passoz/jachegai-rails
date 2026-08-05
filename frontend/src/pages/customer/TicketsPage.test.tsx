import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import TicketsPage from './TicketsPage'

vi.mock('../../services/customerOrders', () => ({
  listCustomerTickets: vi.fn(),
  createCustomerTicket: vi.fn(),
}))

import { listCustomerTickets, createCustomerTicket } from '../../services/customerOrders'

const tickets = [
  { id: 't1', subject: 'Problema no pagamento', status: 'open', created_at: '2026-08-05T12:00:00Z' },
]

describe('TicketsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders tickets list', async () => {
    listCustomerTickets.mockResolvedValue(tickets)
    render(
      <MemoryRouter>
        <TicketsPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Problema no pagamento')).toBeInTheDocument()
  })

  it('opens modal and creates new ticket', async () => {
    listCustomerTickets.mockResolvedValue(tickets)
    createCustomerTicket.mockResolvedValue({
      id: 't2',
      subject: 'Atraso na entrega',
      status: 'open',
      created_at: '2026-08-05T13:00:00Z',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <TicketsPage />
      </MemoryRouter>,
    )

    await screen.findByText('Problema no pagamento')
    await user.click(screen.getByRole('button', { name: /novo ticket/i }))

    expect(screen.getByRole('heading', { name: /novo ticket de suporte/i })).toBeInTheDocument()

    await user.type(screen.getByLabelText(/assunto/i), 'Atraso na entrega')
    await user.type(screen.getByLabelText(/mensagem/i), 'Meu pedido ainda não chegou')

    await user.click(screen.getByRole('button', { name: /abrir ticket/i }))

    await waitFor(() => {
      expect(createCustomerTicket).toHaveBeenCalledWith(
        'Atraso na entrega',
        'Meu pedido ainda não chegou',
        undefined,
      )
    })
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import TicketDetailPage from './TicketDetailPage'

vi.mock('../../services/customerOrders', () => ({
  getCustomerTicket: vi.fn(),
  addCustomerTicketMessage: vi.fn(),
}))

import { getCustomerTicket, addCustomerTicketMessage } from '../../services/customerOrders'

const ticket = {
  id: 't1',
  subject: 'Entrega pendente',
  status: 'open',
  created_at: '2026-08-05T12:00:00Z',
  messages: [
    { id: 'm1', body: 'Meu pedido ainda não chegou', sender: 'customer' as const, created_at: '2026-08-05T12:00:00Z' },
    { id: 'm2', body: 'Estamos verificando com o courier', sender: 'admin' as const, created_at: '2026-08-05T12:05:00Z' },
  ],
}

describe('TicketDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders ticket details and messages timeline', async () => {
    getCustomerTicket.mockResolvedValue(ticket)

    render(
      <MemoryRouter initialEntries={['/customer/tickets/t1']}>
        <Routes>
          <Route path="/customer/tickets/:id" element={<TicketDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Entrega pendente')).toBeInTheDocument()
    expect(screen.getByText('Meu pedido ainda não chegou')).toBeInTheDocument()
    expect(screen.getByText('Estamos verificando com o courier')).toBeInTheDocument()
  })

  it('sends new message and appends to conversation', async () => {
    getCustomerTicket.mockResolvedValue(ticket)
    addCustomerTicketMessage.mockResolvedValue({
      id: 'm3',
      body: 'Obrigado pela resposta',
      sender: 'customer',
      created_at: '2026-08-05T12:10:00Z',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/customer/tickets/t1']}>
        <Routes>
          <Route path="/customer/tickets/:id" element={<TicketDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Entrega pendente')
    const textarea = screen.getByPlaceholderText(/Digite sua resposta.../i)
    await user.type(textarea, 'Obrigado pela resposta')

    await user.click(screen.getByRole('button', { name: /enviar resposta/i }))

    await waitFor(() => {
      expect(addCustomerTicketMessage).toHaveBeenCalledWith('t1', 'Obrigado pela resposta')
    })
  })
})

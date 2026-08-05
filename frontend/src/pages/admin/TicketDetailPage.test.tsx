import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import TicketDetailPage from './TicketDetailPage'

vi.mock('../../services/adminOps', () => ({
  getAdminTicket: vi.fn(),
  addAdminTicketMessage: vi.fn(),
  transitionAdminTicket: vi.fn(),
}))

import {
  getAdminTicket,
  addAdminTicketMessage,
  transitionAdminTicket,
} from '../../services/adminOps'

const ticket = {
  id: 'tk100',
  subject: 'Problema no pagamento',
  status: 'open',
  created_at: '2026-08-05T12:00:00Z',
  messages: [
    { id: 'm1', body: 'Cobrança duplicada', sender: 'customer' as const, created_at: '2026-08-05T12:00:00Z' },
  ],
}

describe('Admin TicketDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders ticket details and transition buttons', async () => {
    getAdminTicket.mockResolvedValue(ticket)
    render(
      <MemoryRouter initialEntries={['/admin/tickets/tk100']}>
        <Routes>
          <Route path="/admin/tickets/:id" element={<TicketDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Problema no pagamento')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /iniciar atendimento/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /resolver/i })).toBeInTheDocument()
  })

  it('transitions ticket state', async () => {
    getAdminTicket.mockResolvedValue(ticket)
    transitionAdminTicket.mockResolvedValue({ ...ticket, status: 'in_progress' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/tickets/tk100']}>
        <Routes>
          <Route path="/admin/tickets/:id" element={<TicketDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Problema no pagamento')
    await user.click(screen.getByRole('button', { name: /iniciar atendimento/i }))

    await waitFor(() => {
      expect(transitionAdminTicket).toHaveBeenCalledWith('tk100', 'start_progress')
    })
  })

  it('sends message as admin', async () => {
    getAdminTicket.mockResolvedValue(ticket)
    addAdminTicketMessage.mockResolvedValue({
      id: 'm2',
      body: 'Estamos estornando o valor',
      sender: 'admin',
      created_at: '2026-08-05T12:10:00Z',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/tickets/tk100']}>
        <Routes>
          <Route path="/admin/tickets/:id" element={<TicketDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Problema no pagamento')
    const textarea = screen.getByPlaceholderText(/Digite sua mensagem como suporte.../i)
    await user.type(textarea, 'Estamos estornando o valor')

    await user.click(screen.getByRole('button', { name: /enviar resposta/i }))

    await waitFor(() => {
      expect(addAdminTicketMessage).toHaveBeenCalledWith('tk100', 'Estamos estornando o valor')
    })
  })
})

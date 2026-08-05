import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import TicketsPage from './TicketsPage'

vi.mock('../../services/adminOps', () => ({
  listAdminTickets: vi.fn(),
}))

import { listAdminTickets } from '../../services/adminOps'

const tickets = [
  { id: 'tk100', subject: 'Problema na entrega', status: 'open', created_at: '2026-08-05T12:00:00Z' },
]

describe('Admin TicketsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders tickets list', async () => {
    listAdminTickets.mockResolvedValue(tickets)
    render(
      <MemoryRouter>
        <TicketsPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Problema na entrega')).toBeInTheDocument()
    expect(screen.getByText('Aberto')).toBeInTheDocument()
  })
})

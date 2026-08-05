import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import PaymentsPage from './PaymentsPage'

vi.mock('../../services/adminOps', () => ({
  listAdminPayments: vi.fn(),
}))

import { listAdminPayments } from '../../services/adminOps'

const payments = [
  { id: 'p100', order_id: 'o1', amount_cents: 6500, currency: 'BRL', status: 'pending' },
]

describe('Admin PaymentsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders payments list', async () => {
    listAdminPayments.mockResolvedValue(payments)
    render(
      <MemoryRouter>
        <PaymentsPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText(/#p100/i)).toBeInTheDocument()
    expect(screen.getByText(/65,00/)).toBeInTheDocument()
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import OrdersPage from './OrdersPage'

vi.mock('../../services/adminOps', () => ({
  listAdminOrders: vi.fn(),
}))

import { listAdminOrders } from '../../services/adminOps'

const orders = [
  { id: 'ao1', status: 'pending', total_cents: 5000, currency: 'BRL', created_at: '2026-08-05T10:00:00Z', items: [] },
]

describe('Admin OrdersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders orders table', async () => {
    listAdminOrders.mockResolvedValue(orders)
    render(
      <MemoryRouter>
        <OrdersPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText(/#ao1/i)).toBeInTheDocument()
    expect(screen.getByText(/50,00/)).toBeInTheDocument()
  })
})

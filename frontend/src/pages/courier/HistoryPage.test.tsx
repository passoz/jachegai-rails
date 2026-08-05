import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import HistoryPage from './HistoryPage'

vi.mock('../../services/courierDeliveries', () => ({
  getDeliveryHistory: vi.fn(),
}))

import { getDeliveryHistory } from '../../services/courierDeliveries'

const historyOrders = [
  {
    id: 'co10',
    order_state: 'delivered',
    seller_name: 'Pizzaria Bella',
    courier_fee_cents: 1200,
    total_cents: 6000,
    currency: 'BRL',
    created_at: '2026-08-05T14:00:00Z',
  },
]

describe('Courier HistoryPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders delivery history list', async () => {
    getDeliveryHistory.mockResolvedValue(historyOrders)
    render(
      <MemoryRouter>
        <HistoryPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Pizzaria Bella')).toBeInTheDocument()
    expect(screen.getByText('Entregue')).toBeInTheDocument()
    expect(screen.getByText(/12,00/)).toBeInTheDocument()
  })
})

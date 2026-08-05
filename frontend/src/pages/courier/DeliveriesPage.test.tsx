import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import DeliveriesPage from './DeliveriesPage'

vi.mock('../../services/courierDeliveries', () => ({
  getActiveDelivery: vi.fn(),
  getEligibleDeliveries: vi.fn(),
  acceptDelivery: vi.fn(),
  pickupDelivery: vi.fn(),
  completeDelivery: vi.fn(),
}))

import {
  getActiveDelivery,
  getEligibleDeliveries,
  acceptDelivery,
} from '../../services/courierDeliveries'

const eligibleOrder = {
  id: 'co1',
  order_state: 'ready',
  seller_name: 'Pizzaria Central',
  delivery_address: 'Rua A, 123',
  courier_fee_cents: 800,
  total_cents: 4500,
  currency: 'BRL',
}

describe('DeliveriesPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders eligible deliveries and accepts order', async () => {
    getActiveDelivery.mockResolvedValue(null)
    getEligibleDeliveries.mockResolvedValue([eligibleOrder])
    acceptDelivery.mockResolvedValue({ ...eligibleOrder, order_state: 'assigned' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <DeliveriesPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Pizzaria Central')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /aceitar entrega/i }))

    await waitFor(() => {
      expect(acceptDelivery).toHaveBeenCalledWith('co1')
    })
  })
})

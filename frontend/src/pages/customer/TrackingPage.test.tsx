import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import TrackingPage from './TrackingPage'

vi.mock('../../services/customerOrders', () => ({
  getCustomerOrderTracking: vi.fn(),
  cancelCustomerOrder: vi.fn(),
}))

import { getCustomerOrderTracking, cancelCustomerOrder } from '../../services/customerOrders'

const tracking = {
  order_id: 'o100',
  order_state: 'assigned',
  courier_location: {
    latitude: -23.5505,
    longitude: -46.6333,
    recorded_at: '2026-08-05T18:00:00Z',
  },
  history: [
    { state: 'pending', at: '2026-08-05T17:30:00Z', actor: 'customer' },
    { state: 'assigned', at: '2026-08-05T18:00:00Z', actor: 'courier' },
  ],
}

describe('TrackingPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders tracking details and courier location textually', async () => {
    getCustomerOrderTracking.mockResolvedValue(tracking)

    render(
      <MemoryRouter initialEntries={['/customer/tracking/o100']}>
        <Routes>
          <Route path="/customer/tracking/:id" element={<TrackingPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText(/Status do pedido: o100/i)).toBeInTheDocument()
    expect(screen.getByText(/Em entrega/i)).toBeInTheDocument()
    expect(screen.getByText(/Courier próximo/i)).toBeInTheDocument()
    expect(screen.getByText(/-23.5505, -46.6333/i)).toBeInTheDocument()
  })

  it('allows order cancellation if state is pending', async () => {
    getCustomerOrderTracking.mockResolvedValue({
      ...tracking,
      order_state: 'pending',
    })
    cancelCustomerOrder.mockResolvedValue(undefined)
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/customer/tracking/o100']}>
        <Routes>
          <Route path="/customer/tracking/:id" element={<TrackingPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText(/Status do pedido: o100/i)
    await user.click(screen.getByRole('button', { name: /cancelar pedido/i }))

    expect(screen.getByText(/Cancelar pedido\?/i)).toBeInTheDocument()
    const confirmBtns = screen.getAllByRole('button', { name: /cancelar/i })
    await user.click(confirmBtns[confirmBtns.length - 1])

    await waitFor(() => {
      expect(cancelCustomerOrder).toHaveBeenCalledWith('o100', 'Cancelado pelo cliente')
    })
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import OrderDetailPage from './OrderDetailPage'

vi.mock('../../services/sellerOrders', () => ({
  getSellerOrder: vi.fn(),
  acceptSellerOrder: vi.fn(),
  rejectSellerOrder: vi.fn(),
  preparingSellerOrder: vi.fn(),
  readySellerOrder: vi.fn(),
}))

import {
  getSellerOrder,
  acceptSellerOrder,
  rejectSellerOrder,
} from '../../services/sellerOrders'

const order = {
  id: 'so100',
  status: 'pending',
  customer_name: 'Ana Maria',
  customer_email: 'ana@example.com',
  subtotal_cents: 3000,
  delivery_fee_cents: 500,
  total_cents: 3500,
  currency: 'BRL',
  items: [{ id: 'i1', name: 'X-Salada', quantity: 2, price_cents: 1500, currency: 'BRL' }],
  created_at: '2026-08-05T18:00:00Z',
  history: [{ state: 'pending', at: '2026-08-05T18:00:00Z', actor: 'customer' }],
}

describe('Seller OrderDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders order details and items', async () => {
    getSellerOrder.mockResolvedValue(order)
    render(
      <MemoryRouter initialEntries={['/seller/orders/so100']}>
        <Routes>
          <Route path="/seller/orders/:id" element={<OrderDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText(/Ana Maria/i)).toBeInTheDocument()
    expect(screen.getByText('X-Salada')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /aceitar pedido/i })).toBeInTheDocument()
  })

  it('accepts pending order', async () => {
    getSellerOrder.mockResolvedValue(order)
    acceptSellerOrder.mockResolvedValue({ ...order, status: 'accepted' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/seller/orders/so100']}>
        <Routes>
          <Route path="/seller/orders/:id" element={<OrderDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText(/Ana Maria/i)
    await user.click(screen.getByRole('button', { name: /aceitar pedido/i }))

    await waitFor(() => {
      expect(acceptSellerOrder).toHaveBeenCalledWith('so100')
    })
  })

  it('rejects order with reason modal', async () => {
    getSellerOrder.mockResolvedValue(order)
    rejectSellerOrder.mockResolvedValue({ ...order, status: 'rejected' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/seller/orders/so100']}>
        <Routes>
          <Route path="/seller/orders/:id" element={<OrderDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText(/Ana Maria/i)
    await user.click(screen.getByRole('button', { name: /rejeitar pedido/i }))

    expect(screen.getByText(/Rejeitar pedido\?/i)).toBeInTheDocument()
    await user.type(screen.getByLabelText(/motivo da rejeição/i), 'Sem estoque')

    const confirmBtns = screen.getAllByRole('button', { name: /rejeitar/i })
    await user.click(confirmBtns[confirmBtns.length - 1])

    await waitFor(() => {
      expect(rejectSellerOrder).toHaveBeenCalledWith('so100', 'Sem estoque')
    })
  })
})

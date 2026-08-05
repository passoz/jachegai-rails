import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import OrderDetailPage from './OrderDetailPage'

vi.mock('../../services/adminOps', () => ({
  getAdminOrder: vi.fn(),
  cancelAdminOrder: vi.fn(),
}))

import { getAdminOrder, cancelAdminOrder } from '../../services/adminOps'

const order = {
  id: 'ao100',
  status: 'pending',
  subtotal_cents: 4000,
  delivery_fee_cents: 500,
  total_cents: 4500,
  currency: 'BRL',
  items: [{ id: 'i1', name: 'Combo Burger', quantity: 1, price_cents: 4000, currency: 'BRL' }],
  created_at: '2026-08-05T10:00:00Z',
}

describe('Admin OrderDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders admin order details and cancel button', async () => {
    getAdminOrder.mockResolvedValue(order)
    render(
      <MemoryRouter initialEntries={['/admin/orders/ao100']}>
        <Routes>
          <Route path="/admin/orders/:id" element={<OrderDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText(/#ao100/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /cancelar pedido/i })).toBeInTheDocument()
  })

  it('cancels order with confirm dialog', async () => {
    getAdminOrder.mockResolvedValue(order)
    cancelAdminOrder.mockResolvedValue({ ...order, status: 'cancelled' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/orders/ao100']}>
        <Routes>
          <Route path="/admin/orders/:id" element={<OrderDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText(/#ao100/i)
    await user.click(screen.getByRole('button', { name: /cancelar pedido/i }))

    expect(screen.getByText(/Cancelar pedido\?/i)).toBeInTheDocument()
    const confirmBtns = screen.getAllByRole('button', { name: /cancelar/i })
    await user.click(confirmBtns[confirmBtns.length - 1])

    await waitFor(() => {
      expect(cancelAdminOrder).toHaveBeenCalledWith('ao100', 'Cancelado pelo administrador')
    })
  })
})

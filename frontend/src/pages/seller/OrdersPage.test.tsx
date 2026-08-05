import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import OrdersPage from './OrdersPage'

vi.mock('../../services/sellerOrders', () => ({
  listSellerOrders: vi.fn(),
}))

import { listSellerOrders } from '../../services/sellerOrders'

const orders = [
  {
    id: 'so10',
    status: 'pending',
    customer_name: 'Carlos Oliveira',
    subtotal_cents: 4000,
    delivery_fee_cents: 500,
    total_cents: 4500,
    currency: 'BRL',
    items: [{ id: 'i1', name: 'X-Burger', quantity: 2, price_cents: 2000 }],
    created_at: '2026-08-05T18:00:00Z',
  },
]

describe('Seller OrdersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders orders list and filter tabs', async () => {
    listSellerOrders.mockResolvedValue(orders)
    render(
      <MemoryRouter>
        <OrdersPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText(/Carlos Oliveira/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /pendentes/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /todos/i })).toBeInTheDocument()
  })

  it('filters list when tab is clicked', async () => {
    listSellerOrders.mockResolvedValue(orders)
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <OrdersPage />
      </MemoryRouter>,
    )

    await screen.findByText(/Carlos Oliveira/i)
    await user.click(screen.getByRole('button', { name: /aceitos/i }))

    expect(listSellerOrders).toHaveBeenCalledWith({ status: 'accepted' })
  })
})

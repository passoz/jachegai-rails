import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import GuestCartWidget from './GuestCartWidget'

vi.mock('../../services/cart', () => ({
  getCart: vi.fn(),
  clearCart: vi.fn(),
  updateCartItem: vi.fn(),
  removeCartItem: vi.fn(),
}))

import { getCart, clearCart, updateCartItem, removeCartItem } from '../../services/cart'

const cart = {
  items: [
    { id: 'i1', product_id: 'p1', quantity: 2, name: 'Produto X', price_cents: 1250, currency: 'BRL' },
    { id: 'i2', product_id: 'p2', quantity: 1, name: 'Produto Y', price_cents: 300, currency: 'BRL' },
  ],
  total_cents: 2800,
  currency: 'BRL',
}

describe('GuestCartWidget', () => {
  beforeEach(() => vi.clearAllMocks())

  it('shows item count badge', async () => {
    getCart.mockResolvedValue(cart)
    render(
      <MemoryRouter>
        <GuestCartWidget />
      </MemoryRouter>,
    )
    expect(await screen.findByText('3')).toBeInTheDocument()
  })

  it('opens panel with items and total on click', async () => {
    getCart.mockResolvedValue(cart)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <GuestCartWidget />
      </MemoryRouter>,
    )
    await user.click(screen.getByRole('button', { name: /carrinho/i }))
    expect(await screen.findByText('Produto X')).toBeInTheDocument()
    expect(await screen.findByText('Produto Y')).toBeInTheDocument()
    expect(await screen.findByText(/28,00/)).toBeInTheDocument()
  })

  it('removes item when clicking remove', async () => {
    getCart.mockResolvedValue(cart)
    removeCartItem.mockResolvedValue({
      items: [cart.items[1]],
      total_cents: 300,
      currency: 'BRL',
    })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <GuestCartWidget />
      </MemoryRouter>,
    )
    await user.click(screen.getByRole('button', { name: /carrinho/i }))
    const removeButtons = await screen.findAllByRole('button', { name: /remover/i })
    await user.click(removeButtons[0])
    await waitFor(() => expect(removeCartItem).toHaveBeenCalledWith('i1'))
  })

  it('updates quantity when clicking increment', async () => {
    getCart.mockResolvedValue(cart)
    updateCartItem.mockResolvedValue(cart)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <GuestCartWidget />
      </MemoryRouter>,
    )
    await user.click(screen.getByRole('button', { name: /carrinho/i }))
    const incButtons = await screen.findAllByRole('button', { name: /aumentar/i })
    await user.click(incButtons[0])
    await waitFor(() => expect(updateCartItem).toHaveBeenCalledWith('i1', 3))
  })

  it('shows empty state for empty cart', async () => {
    getCart.mockResolvedValue({ items: [], total_cents: 0, currency: 'BRL' })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <GuestCartWidget />
      </MemoryRouter>,
    )
    await user.click(screen.getByRole('button', { name: /carrinho/i }))
    expect(await screen.findByText(/carrinho vazio/i)).toBeInTheDocument()
  })

  it('clears cart when clicking limpar', async () => {
    getCart.mockResolvedValue(cart)
    clearCart.mockResolvedValue(undefined)
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <GuestCartWidget />
      </MemoryRouter>,
    )
    await user.click(screen.getByRole('button', { name: /carrinho/i }))
    await screen.findByText('Produto X')
    await user.click(screen.getByRole('button', { name: /limpar/i }))
    expect(clearCart).toHaveBeenCalled()
  })
})

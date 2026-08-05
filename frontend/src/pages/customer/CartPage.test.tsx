import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import CartPage from './CartPage'

vi.mock('../../services/customerCart', () => ({
  getCustomerCart: vi.fn(),
  clearCustomerCart: vi.fn(),
  updateCustomerCartItem: vi.fn(),
  removeCustomerCartItem: vi.fn(),
  handoffGuestCart: vi.fn(),
}))

import {
  getCustomerCart,
  clearCustomerCart,
  updateCustomerCartItem,
  removeCustomerCartItem,
  handoffGuestCart,
} from '../../services/customerCart'

const cartData = {
  items: [
    { id: 'ci1', product_id: 'p1', name: 'Pizza Calabresa', quantity: 2, price_cents: 3000, currency: 'BRL' },
  ],
  subtotal_cents: 6000,
  delivery_fee_cents: 700,
  total_cents: 6700,
  currency: 'BRL',
}

describe('CartPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('triggers automatic handoff on mount and loads cart', async () => {
    handoffGuestCart.mockResolvedValue(cartData)
    getCustomerCart.mockResolvedValue(cartData)

    render(
      <MemoryRouter>
        <CartPage />
      </MemoryRouter>,
    )

    await waitFor(() => {
      expect(handoffGuestCart).toHaveBeenCalled()
      expect(getCustomerCart).toHaveBeenCalled()
    })

    expect(await screen.findByText('Pizza Calabresa')).toBeInTheDocument()
    expect(screen.getByText(/67,00/)).toBeInTheDocument()
  })

  it('updates item quantity', async () => {
    handoffGuestCart.mockResolvedValue(cartData)
    getCustomerCart.mockResolvedValue(cartData)
    updateCustomerCartItem.mockResolvedValue({
      ...cartData,
      items: [{ ...cartData.items[0], quantity: 3 }],
      subtotal_cents: 9000,
      total_cents: 9700,
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CartPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizza Calabresa')
    const incBtn = screen.getByRole('button', { name: /Aumentar/i })
    await user.click(incBtn)

    await waitFor(() => {
      expect(updateCustomerCartItem).toHaveBeenCalledWith('ci1', 3)
    })
  })

  it('removes item', async () => {
    handoffGuestCart.mockResolvedValue(cartData)
    getCustomerCart.mockResolvedValue(cartData)
    removeCustomerCartItem.mockResolvedValue({
      items: [],
      subtotal_cents: 0,
      delivery_fee_cents: 0,
      total_cents: 0,
      currency: 'BRL',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CartPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizza Calabresa')
    await user.click(screen.getByRole('button', { name: /remover/i }))

    await waitFor(() => {
      expect(removeCustomerCartItem).toHaveBeenCalledWith('ci1')
    })
  })

  it('clears cart on confirm', async () => {
    handoffGuestCart.mockResolvedValue(cartData)
    getCustomerCart.mockResolvedValue(cartData)
    clearCustomerCart.mockResolvedValue(undefined)
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CartPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizza Calabresa')
    await user.click(screen.getByRole('button', { name: /limpar carrinho/i }))

    expect(screen.getByRole('heading', { name: 'Limpar carrinho?' })).toBeInTheDocument()
    const confirmButtons = screen.getAllByRole('button', { name: /limpar/i })
    await user.click(confirmButtons[confirmButtons.length - 1])

    await waitFor(() => {
      expect(clearCustomerCart).toHaveBeenCalled()
    })
  })

  it('shows empty state when cart is empty', async () => {
    handoffGuestCart.mockResolvedValue({ items: [], subtotal_cents: 0, delivery_fee_cents: 0, total_cents: 0, currency: 'BRL' })
    getCustomerCart.mockResolvedValue({ items: [], subtotal_cents: 0, delivery_fee_cents: 0, total_cents: 0, currency: 'BRL' })

    render(
      <MemoryRouter>
        <CartPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText(/Seu carrinho está vazio/i)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /explorar sellers/i })).toBeInTheDocument()
  })
})

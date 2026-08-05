import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import CheckoutPage from './CheckoutPage'

vi.mock('../../services/customerCart', () => ({
  getCustomerCart: vi.fn(),
  checkoutCustomerCart: vi.fn(),
}))

vi.mock('../../services/customer', () => ({
  listCustomerAddresses: vi.fn(),
  createCustomerAddress: vi.fn(),
}))

import { getCustomerCart, checkoutCustomerCart } from '../../services/customerCart'
import { listCustomerAddresses } from '../../services/customer'

const cartData = {
  items: [
    { id: 'ci1', product_id: 'p1', name: 'Pizza Calabresa', quantity: 2, price_cents: 3000, currency: 'BRL' },
  ],
  subtotal_cents: 6000,
  delivery_fee_cents: 700,
  total_cents: 6700,
  currency: 'BRL',
}

const addresses = [
  {
    id: 'a1',
    street: 'Rua das Flores',
    number: '123',
    neighborhood: 'Centro',
    city: 'São Paulo',
    state: 'SP',
    zip_code: '01000-000',
    default: true,
  },
]

describe('CheckoutPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders cart summary and selects default address', async () => {
    getCustomerCart.mockResolvedValue(cartData)
    listCustomerAddresses.mockResolvedValue(addresses)

    render(
      <MemoryRouter>
        <CheckoutPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Pizza Calabresa')).toBeInTheDocument()
    expect(screen.getByText(/Rua das Flores/)).toBeInTheDocument()
  })

  it('places order successfully on button click', async () => {
    getCustomerCart.mockResolvedValue(cartData)
    listCustomerAddresses.mockResolvedValue(addresses)
    checkoutCustomerCart.mockResolvedValue({ id: 'o100', status: 'pending', total_cents: 6700, currency: 'BRL' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CheckoutPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizza Calabresa')
    await user.click(screen.getByRole('button', { name: /confirmar pedido/i }))

    await waitFor(() => {
      expect(checkoutCustomerCart).toHaveBeenCalledWith('a1')
    })
  })

  it('handles insufficient_inventory error 422', async () => {
    getCustomerCart.mockResolvedValue(cartData)
    listCustomerAddresses.mockResolvedValue(addresses)
    const err = {
      isAxiosError: true,
      response: { data: { error: { code: 'insufficient_inventory', message: 'estoque insuficiente' } } },
    }
    checkoutCustomerCart.mockRejectedValue(err)
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CheckoutPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizza Calabresa')
    await user.click(screen.getByRole('button', { name: /confirmar pedido/i }))

    expect(await screen.findByText(/Estoque insuficiente para um ou mais itens/i)).toBeInTheDocument()
  })
})

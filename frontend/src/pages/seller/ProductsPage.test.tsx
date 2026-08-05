import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ProductsPage from './ProductsPage'

vi.mock('../../services/sellerCatalog', () => ({
  listSellerProducts: vi.fn(),
  listSellerCategories: vi.fn(),
  createSellerProduct: vi.fn(),
  activateSellerProduct: vi.fn(),
  deactivateSellerProduct: vi.fn(),
  deleteSellerProduct: vi.fn(),
}))

import {
  listSellerProducts,
  listSellerCategories,
  createSellerProduct,
} from '../../services/sellerCatalog'

const products = [
  {
    id: 'p1',
    name: 'Pizza Margherita',
    price_cents: 4500,
    currency: 'BRL',
    active: true,
    category_id: 'cat1',
  },
]
const categories = [{ id: 'cat1', name: 'Pizzas', position: 1 }]

describe('ProductsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders products table', async () => {
    listSellerProducts.mockResolvedValue(products)
    listSellerCategories.mockResolvedValue(categories)

    render(
      <MemoryRouter>
        <ProductsPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Pizza Margherita')).toBeInTheDocument()
    expect(screen.getByText(/45,00/)).toBeInTheDocument()
  })

  it('creates product via modal with decimal price conversion', async () => {
    listSellerProducts.mockResolvedValue(products)
    listSellerCategories.mockResolvedValue(categories)
    createSellerProduct.mockResolvedValue({
      id: 'p2',
      name: 'Refrigerante',
      price_cents: 800,
      currency: 'BRL',
      active: true,
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <ProductsPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizza Margherita')
    await user.click(screen.getByRole('button', { name: /novo produto/i }))

    await user.type(screen.getByLabelText(/nome do produto/i), 'Refrigerante')
    await user.type(screen.getByLabelText(/preço \(r\$\)/i), '8,00')

    await user.click(screen.getByRole('button', { name: /salvar produto/i }))

    await waitFor(() => {
      expect(createSellerProduct).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Refrigerante',
          price_cents: 800,
        }),
      )
    })
  })
})

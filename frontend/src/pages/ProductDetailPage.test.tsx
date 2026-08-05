import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ProductDetailPage from './ProductDetailPage'

vi.mock('../services/public', () => ({
  getProduct: vi.fn(),
}))

vi.mock('../services/cart', () => ({
  addCartItem: vi.fn(),
}))

import { getProduct } from '../services/public'
import { addCartItem } from '../services/cart'

const product = {
  id: 'p1',
  seller_id: 's1',
  name: 'Produto X',
  description: 'Um produto legal',
  price_cents: 1250,
  currency: 'BRL',
  active: true,
}

describe('ProductDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders product details and formatted price', async () => {
    getProduct.mockResolvedValue(product)
    render(
      <MemoryRouter initialEntries={['/products/p1']}>
        <ProductDetailPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Produto X')).toBeInTheDocument()
    expect(await screen.findByText(/12,50/)).toBeInTheDocument()
  })

  it('increments and decrements quantity', async () => {
    getProduct.mockResolvedValue(product)
    const user = userEvent.setup()
    render(
      <MemoryRouter initialEntries={['/products/p1']}>
        <ProductDetailPage />
      </MemoryRouter>,
    )
    await screen.findByText('Produto X')
    expect(screen.getByTestId('quantity')).toHaveTextContent('1')
    await user.click(screen.getByRole('button', { name: 'Aumentar quantidade' }))
    expect(screen.getByTestId('quantity')).toHaveTextContent('2')
    await user.click(screen.getByRole('button', { name: 'Diminuir quantidade' }))
    expect(screen.getByTestId('quantity')).toHaveTextContent('1')
  })

  it('adds product to cart with selected quantity', async () => {
    getProduct.mockResolvedValue(product)
    addCartItem.mockResolvedValue({ items: [], total_cents: 0, currency: 'BRL' })
    const user = userEvent.setup()
    render(
      <MemoryRouter initialEntries={['/products/p1']}>
        <ProductDetailPage />
      </MemoryRouter>,
    )
    await screen.findByText('Produto X')
    await user.click(screen.getByRole('button', { name: 'Aumentar quantidade' }))
    await user.click(screen.getByRole('button', { name: /adicionar ao carrinho/i }))
    await waitFor(() => expect(addCartItem).toHaveBeenCalledWith('p1', 2))
  })

  it('shows error state on load failure', async () => {
    getProduct.mockRejectedValue(new Error('not found'))
    render(
      <MemoryRouter initialEntries={['/products/p1']}>
        <ProductDetailPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText(/Não foi possível carregar o produto/)).toBeInTheDocument()
  })
})

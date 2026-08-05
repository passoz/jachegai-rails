import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import SellerDetailPage from './SellerDetailPage'

vi.mock('../services/public', () => ({
  getSeller: vi.fn(),
  listSellerProducts: vi.fn(),
}))

vi.mock('../services/cart', () => ({
  addCartItem: vi.fn(),
}))

vi.mock('../contexts/useAuth', () => ({
  useAuth: () => ({ isAuthenticated: true }),
}))

import { getSeller, listSellerProducts } from '../services/public'
import { addCartItem } from '../services/cart'

const seller = {
  id: 's1',
  name: 'Loja Teste',
  slug: 'loja-teste',
  moderation_state: 'approved',
  description: 'Uma loja',
  address_city: 'São Paulo',
  address_state: 'SP',
}

const products = [
  { id: 'p1', seller_id: 's1', name: 'Produto X', price_cents: 1250, currency: 'BRL', active: true },
  { id: 'p2', seller_id: 's1', name: 'Produto Y', price_cents: 300, currency: 'BRL', active: true },
]

function renderWithParams(id = 's1') {
  return render(
    <MemoryRouter initialEntries={[`/sellers/${id}`]}>
      <Routes>
        <Route path="/sellers/:id" element={<SellerDetailPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('SellerDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders seller info and products', async () => {
    getSeller.mockResolvedValue(seller)
    listSellerProducts.mockResolvedValue(products)
    renderWithParams()
    expect(await screen.findByText('Loja Teste')).toBeInTheDocument()
    expect(await screen.findByText('Produto X')).toBeInTheDocument()
    expect(await screen.findByText(/12,50/)).toBeInTheDocument()
    expect(await screen.findByText('Produto Y')).toBeInTheDocument()
    expect(await screen.findByText(/São Paulo/)).toBeInTheDocument()
  })

  it('shows error state when seller not found', async () => {
    getSeller.mockRejectedValue(new Error('not found'))
    listSellerProducts.mockRejectedValue(new Error('not found'))
    renderWithParams()
    expect(await screen.findByText(/Não foi possível carregar a loja/)).toBeInTheDocument()
  })

  it('shows empty state when no products', async () => {
    getSeller.mockResolvedValue(seller)
    listSellerProducts.mockResolvedValue([])
    renderWithParams()
    expect(await screen.findByText('Nenhum produto disponível')).toBeInTheDocument()
  })

  it('adds product to cart from product card', async () => {
    getSeller.mockResolvedValue(seller)
    listSellerProducts.mockResolvedValue(products)
    addCartItem.mockResolvedValue({ items: [], total_cents: 0, currency: 'BRL' })
    const user = userEvent.setup()
    renderWithParams()
    await screen.findByText('Produto X')
    const buttons = await screen.findAllByRole('button', { name: /adicionar ao carrinho/i })
    await user.click(buttons[0])
    await waitFor(() => expect(addCartItem).toHaveBeenCalledWith('p1', 1, false))
  })

  it('shows replace dialog when cart has different seller', async () => {
    getSeller.mockResolvedValue(seller)
    listSellerProducts.mockResolvedValue(products)
    const conflictError = {
      isAxiosError: true,
      response: {
        data: {
          error: { code: 'seller_conflict', message: 'seu carrinho contém itens de outro vendedor' },
        },
      },
    }
    addCartItem.mockRejectedValueOnce(conflictError).mockResolvedValueOnce({ items: [], total_cents: 0, currency: 'BRL' })
    const user = userEvent.setup()
    renderWithParams()
    await screen.findByText('Produto X')
    const buttons = await screen.findAllByRole('button', { name: /adicionar ao carrinho/i })
    await user.click(buttons[0])
    expect(await screen.findByText(/Seu carrinho será substituído/)).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /continuar/i }))
    await waitFor(() => expect(addCartItem).toHaveBeenCalledTimes(2))
    expect(addCartItem).toHaveBeenLastCalledWith('p1', 1, true)
  })
})

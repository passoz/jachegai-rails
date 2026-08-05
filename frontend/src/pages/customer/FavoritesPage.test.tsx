import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import FavoritesPage from './FavoritesPage'

vi.mock('../../services/customer', () => ({
  listCustomerFavorites: vi.fn(),
  removeCustomerFavorite: vi.fn(),
}))

import { listCustomerFavorites, removeCustomerFavorite } from '../../services/customer'

const favorites = [
  { id: 'f1', seller_id: 's1', seller_name: 'Pizzaria Bella', seller_slug: 'pizzaria-bella' },
  { id: 'f2', seller_id: 's2', seller_name: 'Burger King', seller_slug: 'burger-king' },
]

describe('FavoritesPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders favorites grid', async () => {
    listCustomerFavorites.mockResolvedValue(favorites)
    render(
      <MemoryRouter>
        <FavoritesPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Pizzaria Bella')).toBeInTheDocument()
    expect(screen.getByText('Burger King')).toBeInTheDocument()
  })

  it('removes favorite on button click', async () => {
    listCustomerFavorites.mockResolvedValue(favorites)
    removeCustomerFavorite.mockResolvedValue(undefined)
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <FavoritesPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizzaria Bella')
    const removeBtns = screen.getAllByRole('button', { name: /remover/i })
    await user.click(removeBtns[0])

    await waitFor(() => {
      expect(removeCustomerFavorite).toHaveBeenCalledWith('f1')
    })
  })

  it('shows empty state with link to /sellers when no favorites', async () => {
    listCustomerFavorites.mockResolvedValue([])
    render(
      <MemoryRouter>
        <FavoritesPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText(/Nenhum seller favoritado/i)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /explorar sellers/i })).toBeInTheDocument()
  })
})

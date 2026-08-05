import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import CategoriesPage from './CategoriesPage'

vi.mock('../../services/sellerCatalog', () => ({
  listSellerCategories: vi.fn(),
  createSellerCategory: vi.fn(),
  deleteSellerCategory: vi.fn(),
  reorderSellerCategories: vi.fn(),
}))

import {
  listSellerCategories,
  createSellerCategory,
  deleteSellerCategory,
} from '../../services/sellerCatalog'

const categories = [
  { id: 'cat1', name: 'Pizzas', position: 1 },
  { id: 'cat2', name: 'Bebidas', position: 2 },
]

describe('CategoriesPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders categories list', async () => {
    listSellerCategories.mockResolvedValue(categories)
    render(
      <MemoryRouter>
        <CategoriesPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Pizzas')).toBeInTheDocument()
    expect(screen.getByText('Bebidas')).toBeInTheDocument()
  })

  it('creates category', async () => {
    listSellerCategories.mockResolvedValue(categories)
    createSellerCategory.mockResolvedValue({ id: 'cat3', name: 'Sobremesas', position: 3 })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CategoriesPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizzas')
    await user.click(screen.getByRole('button', { name: /nova categoria/i }))

    await user.type(screen.getByLabelText(/nome da categoria/i), 'Sobremesas')
    await user.click(screen.getByRole('button', { name: /salvar categoria/i }))

    await waitFor(() => {
      expect(createSellerCategory).toHaveBeenCalledWith('Sobremesas')
    })
  })

  it('deletes category with confirm dialog', async () => {
    listSellerCategories.mockResolvedValue(categories)
    deleteSellerCategory.mockResolvedValue(undefined)
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <CategoriesPage />
      </MemoryRouter>,
    )

    await screen.findByText('Pizzas')
    const deleteBtns = screen.getAllByRole('button', { name: /excluir/i })
    await user.click(deleteBtns[0])

    expect(screen.getByText(/Excluir categoria\?/i)).toBeInTheDocument()
    const confirmBtns = screen.getAllByRole('button', { name: /excluir/i })
    await user.click(confirmBtns[confirmBtns.length - 1])

    await waitFor(() => {
      expect(deleteSellerCategory).toHaveBeenCalledWith('cat1')
    })
  })
})

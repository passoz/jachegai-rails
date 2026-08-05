import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import SellersPage from './SellersPage'

vi.mock('../services/public', () => ({
  listSellers: vi.fn(),
}))

import { listSellers } from '../services/public'

const sellers = [
  { id: 's1', name: 'Loja Teste', slug: 'loja-teste', moderation_state: 'approved' },
  { id: 's2', name: 'Outra Loja', slug: 'outra-loja', moderation_state: 'approved' },
]

describe('SellersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders title and seller cards', async () => {
    listSellers.mockResolvedValue({ sellers, pagination: { page: 1, per_page: 10, total: 2, total_pages: 1 } })
    render(
      <MemoryRouter>
        <SellersPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Loja Teste')).toBeInTheDocument()
    expect(await screen.findByText('Outra Loja')).toBeInTheDocument()
  })

  it('calls listSellers with page 1 on mount', async () => {
    listSellers.mockResolvedValue({ sellers, pagination: { page: 1, per_page: 10, total: 2, total_pages: 1 } })
    render(
      <MemoryRouter>
        <SellersPage />
      </MemoryRouter>,
    )
    await screen.findByText('Loja Teste')
    expect(listSellers).toHaveBeenCalledWith({ page: 1 })
  })

  it('shows pagination controls when multiple pages', async () => {
    listSellers.mockResolvedValue({
      sellers: [sellers[0]],
      pagination: { page: 1, per_page: 1, total: 2, total_pages: 2 },
    })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <SellersPage />
      </MemoryRouter>,
    )
    await screen.findByText('Loja Teste')
    expect(screen.getByText('Página 1 de 2')).toBeInTheDocument()
    listSellers.mockResolvedValue({
      sellers: [sellers[1]],
      pagination: { page: 2, per_page: 1, total: 2, total_pages: 2 },
    })
    await user.click(screen.getByRole('button', { name: /próxima/i }))
    expect(await screen.findByText('Outra Loja')).toBeInTheDocument()
    expect(screen.getByText('Página 2 de 2')).toBeInTheDocument()
  })

  it('shows error state and retries', async () => {
    listSellers.mockRejectedValueOnce(new Error('network')).mockResolvedValueOnce({
      sellers,
      pagination: { page: 1, per_page: 10, total: 2, total_pages: 1 },
    })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <SellersPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText(/Não foi possível carregar os sellers/)).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /tentar novamente/i }))
    expect(await screen.findByText('Loja Teste')).toBeInTheDocument()
  })
})

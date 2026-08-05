import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import HomePage from './HomePage'

vi.mock('../services/public', () => ({
  listSellers: vi.fn(),
}))

vi.mock('../contexts/useAuth', () => ({
  useAuth: () => ({ isAuthenticated: false }),
}))

import { listSellers } from '../services/public'

const sellers = [
  { id: 's1', name: 'Loja Teste', slug: 'loja-teste', moderation_state: 'approved', description: 'Loja legal' },
  { id: 's2', name: 'Outra Loja', slug: 'outra-loja', moderation_state: 'approved' },
]

describe('HomePage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders hero and CTA', () => {
    listSellers.mockResolvedValue({ sellers: [], pagination: undefined })
    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )
    expect(screen.getByText(/Seu delivery/)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Explorar sellers' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Criar conta' })).toBeInTheDocument()
  })

  it('renders partner and courier CTAs', () => {
    listSellers.mockResolvedValue({ sellers: [], pagination: undefined })
    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )
    expect(screen.getByRole('link', { name: /Seja um seller/ })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Seja um courier/ })).toBeInTheDocument()
  })

  it('renders seller cards when list loads', async () => {
    listSellers.mockResolvedValue({ sellers, pagination: { page: 1, per_page: 6, total: 2, total_pages: 1 } })
    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Loja Teste')).toBeInTheDocument()
    expect(await screen.findByText('Outra Loja')).toBeInTheDocument()
    expect(listSellers).toHaveBeenCalledWith({ limit: 6 })
  })

  it('shows error state and retries', async () => {
    listSellers.mockRejectedValueOnce(new Error("network")).mockResolvedValueOnce({ sellers, pagination: undefined })
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )
    expect(await screen.findByText(/Não foi possível carregar/)).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: /Tentar novamente/i }))
    expect(await screen.findByText('Loja Teste')).toBeInTheDocument()
  })

  it('shows empty state when no sellers', async () => {
    listSellers.mockResolvedValue({ sellers: [], pagination: undefined })
    render(
      <MemoryRouter>
        <HomePage />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Nenhum seller disponível')).toBeInTheDocument()
  })
})

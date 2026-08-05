import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import SellersPage from './SellersPage'

vi.mock('../../services/adminModeration', () => ({
  listAdminSellers: vi.fn(),
}))

import { listAdminSellers } from '../../services/adminModeration'

const sellers = [
  { id: 's1', name: 'Padaria Alfa', moderation_state: 'pending_review', created_at: '2026-08-05T10:00:00Z' },
]

describe('Admin SellersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders sellers list', async () => {
    listAdminSellers.mockResolvedValue(sellers)
    render(
      <MemoryRouter>
        <SellersPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Padaria Alfa')).toBeInTheDocument()
    expect(screen.getByText('Aguardando análise')).toBeInTheDocument()
  })
})

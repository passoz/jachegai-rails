import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import UsersPage from './UsersPage'

vi.mock('../../services/admin', () => ({
  listAdminUsers: vi.fn(),
}))

import { listAdminUsers } from '../../services/admin'

const usersList = [
  {
    id: 'u1',
    name: 'Carlos Santos',
    email: 'carlos@example.com',
    roles: ['customer'],
    active: true,
  },
]

describe('Admin UsersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders users table', async () => {
    listAdminUsers.mockResolvedValue(usersList)
    render(
      <MemoryRouter>
        <UsersPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Carlos Santos')).toBeInTheDocument()
    expect(screen.getByText('carlos@example.com')).toBeInTheDocument()
    expect(screen.getByText('Ativo')).toBeInTheDocument()
  })
})

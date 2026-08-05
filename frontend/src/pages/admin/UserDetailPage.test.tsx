import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import UserDetailPage from './UserDetailPage'

vi.mock('../../services/admin', () => ({
  getAdminUser: vi.fn(),
  disableAdminUser: vi.fn(),
  enableAdminUser: vi.fn(),
}))

import { getAdminUser, disableAdminUser } from '../../services/admin'

const userData = {
  id: 'u100',
  name: 'Fernanda Lima',
  email: 'fernanda@example.com',
  roles: ['customer'],
  active: true,
  created_at: '2026-08-01T10:00:00Z',
}

describe('Admin UserDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders user details', async () => {
    getAdminUser.mockResolvedValue(userData)
    render(
      <MemoryRouter initialEntries={['/admin/users/u100']}>
        <Routes>
          <Route path="/admin/users/:id" element={<UserDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Fernanda Lima')).toBeInTheDocument()
    expect(screen.getByText('fernanda@example.com')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /desabilitar usuário/i })).toBeInTheDocument()
  })

  it('disables user via modal confirmation', async () => {
    getAdminUser.mockResolvedValue(userData)
    disableAdminUser.mockResolvedValue({ ...userData, active: false })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/users/u100']}>
        <Routes>
          <Route path="/admin/users/:id" element={<UserDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Fernanda Lima')
    await user.click(screen.getByRole('button', { name: /desabilitar usuário/i }))

    expect(screen.getByText(/Desabilitar usuário\?/i)).toBeInTheDocument()
    const confirmBtns = screen.getAllByRole('button', { name: /desabilitar/i })
    await user.click(confirmBtns[confirmBtns.length - 1])

    await waitFor(() => {
      expect(disableAdminUser).toHaveBeenCalledWith('u100')
    })
  })
})

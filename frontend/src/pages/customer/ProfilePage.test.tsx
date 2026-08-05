import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ProfilePage from './ProfilePage'

vi.mock('../../services/customer', () => ({
  getCustomerProfile: vi.fn(),
  updateCustomerProfile: vi.fn(),
}))

import { getCustomerProfile, updateCustomerProfile } from '../../services/customer'

const profile = {
  id: 'c1',
  name: 'Maria Souza',
  email: 'maria@example.com',
  created_at: '2026-01-15T10:00:00Z',
}

describe('ProfilePage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders profile data and readonly email', async () => {
    getCustomerProfile.mockResolvedValue(profile)
    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )
    expect(await screen.findByDisplayValue('Maria Souza')).toBeInTheDocument()
    const emailInput = screen.getByDisplayValue('maria@example.com')
    expect(emailInput).toBeDisabled()
  })

  it('updates profile name on save', async () => {
    getCustomerProfile.mockResolvedValue(profile)
    updateCustomerProfile.mockResolvedValue({ ...profile, name: 'Maria Silva' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )

    const input = await screen.findByDisplayValue('Maria Souza')
    await user.clear(input)
    await user.type(input, 'Maria Silva')
    await user.click(screen.getByRole('button', { name: /salvar/i }))

    await waitFor(() => {
      expect(updateCustomerProfile).toHaveBeenCalledWith('Maria Silva')
    })
    expect(await screen.findByText(/Perfil atualizado com sucesso/i)).toBeInTheDocument()
  })

  it('shows error message on update failure', async () => {
    getCustomerProfile.mockResolvedValue(profile)
    updateCustomerProfile.mockRejectedValue(new Error('error'))
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )

    await screen.findByDisplayValue('Maria Souza')
    await user.click(screen.getByRole('button', { name: /salvar/i }))

    expect(await screen.findByText(/Não foi possível atualizar o perfil/i)).toBeInTheDocument()
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ProfilePage from './ProfilePage'

vi.mock('../../services/courier', () => ({
  getCourierProfile: vi.fn(),
  updateCourierProfile: vi.fn(),
}))

import { getCourierProfile, updateCourierProfile } from '../../services/courier'

const profile = {
  id: 'c1',
  full_name: 'Carlos Oliveira',
  document: '12345678900',
  vehicle_type: 'moto',
  phone: '11988888888',
  approval_state: 'approved',
  operational_state: 'available',
}

describe('Courier ProfilePage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders profile and badges', async () => {
    getCourierProfile.mockResolvedValue(profile)
    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )

    expect(await screen.findByDisplayValue('Carlos Oliveira')).toBeInTheDocument()
    expect(screen.getByText('Aprovado')).toBeInTheDocument()
    expect(screen.getByText('Disponível')).toBeInTheDocument()
  })

  it('updates courier profile data', async () => {
    getCourierProfile.mockResolvedValue(profile)
    updateCourierProfile.mockResolvedValue({ ...profile, full_name: 'Carlos Novo' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )

    const input = await screen.findByDisplayValue('Carlos Oliveira')
    await user.clear(input)
    await user.type(input, 'Carlos Novo')

    await user.click(screen.getByRole('button', { name: /salvar/i }))

    await waitFor(() => {
      expect(updateCourierProfile).toHaveBeenCalledWith(
        expect.objectContaining({ full_name: 'Carlos Novo' }),
      )
    })
  })
})

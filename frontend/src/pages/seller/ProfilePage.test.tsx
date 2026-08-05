import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ProfilePage from './ProfilePage'

vi.mock('../../services/seller', () => ({
  getSellerProfile: vi.fn(),
  updateSellerProfile: vi.fn(),
}))

import { getSellerProfile, updateSellerProfile } from '../../services/seller'

const profile = {
  id: 's1',
  name: 'Loja Exemplo',
  slug: 'loja-exemplo',
  description: 'Descrição antiga',
  contact_phone: '11999999999',
  moderation_state: 'approved',
}

describe('Seller ProfilePage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders profile data and badge', async () => {
    getSellerProfile.mockResolvedValue(profile)
    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )
    expect(await screen.findByDisplayValue('Loja Exemplo')).toBeInTheDocument()
    expect(screen.getByText('Aprovado')).toBeInTheDocument()
  })

  it('updates profile data on save', async () => {
    getSellerProfile.mockResolvedValue(profile)
    updateSellerProfile.mockResolvedValue({ ...profile, name: 'Loja Nova' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <ProfilePage />
      </MemoryRouter>,
    )

    const nameInput = await screen.findByDisplayValue('Loja Exemplo')
    await user.clear(nameInput)
    await user.type(nameInput, 'Loja Nova')

    await user.click(screen.getByRole('button', { name: /salvar/i }))

    await waitFor(() => {
      expect(updateSellerProfile).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'Loja Nova' }),
      )
    })
  })
})

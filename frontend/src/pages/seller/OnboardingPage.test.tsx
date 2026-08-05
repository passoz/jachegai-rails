import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import OnboardingPage from './OnboardingPage'

vi.mock('../../services/seller', () => ({
  submitSellerOnboarding: vi.fn(),
  getSellerProfile: vi.fn(),
}))

import { submitSellerOnboarding, getSellerProfile } from '../../services/seller'

describe('OnboardingPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders onboarding form and submits', async () => {
    getSellerProfile.mockRejectedValue(new Error('not seller yet'))
    submitSellerOnboarding.mockResolvedValue({
      id: 's1',
      name: 'Padaria Central',
      slug: 'padaria-central',
      moderation_state: 'pending_review',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <OnboardingPage />
      </MemoryRouter>,
    )

    expect(await screen.findByRole('heading', { name: /cadastro de seller/i })).toBeInTheDocument()

    await user.type(screen.getByLabelText(/nome da loja/i), 'Padaria Central')
    await user.click(screen.getByRole('button', { name: /enviar para aprovação/i }))

    await waitFor(() => {
      expect(submitSellerOnboarding).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'Padaria Central' }),
      )
    })

    expect(await screen.findByText(/Sua loja foi enviada para análise/i)).toBeInTheDocument()
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import OnboardingPage from './OnboardingPage'

vi.mock('../../services/courier', () => ({
  submitCourierOnboarding: vi.fn(),
  getCourierProfile: vi.fn(),
}))

import { submitCourierOnboarding, getCourierProfile } from '../../services/courier'

describe('Courier OnboardingPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders onboarding form and submits', async () => {
    getCourierProfile.mockRejectedValue(new Error('not courier'))
    submitCourierOnboarding.mockResolvedValue({
      id: 'c1',
      full_name: 'Marcos Silva',
      vehicle_type: 'moto',
      approval_state: 'pending_review',
      operational_state: 'offline',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <OnboardingPage />
      </MemoryRouter>,
    )

    expect(await screen.findByRole('heading', { name: /cadastro de entregador/i })).toBeInTheDocument()

    await user.type(screen.getByLabelText(/nome completo/i), 'Marcos Silva')
    await user.click(screen.getByRole('button', { name: /cadastrar como entregador/i }))

    await waitFor(() => {
      expect(submitCourierOnboarding).toHaveBeenCalledWith(
        expect.objectContaining({ full_name: 'Marcos Silva' }),
      )
    })

    expect(await screen.findByText(/Cadastro enviado para análise/i)).toBeInTheDocument()
  })
})

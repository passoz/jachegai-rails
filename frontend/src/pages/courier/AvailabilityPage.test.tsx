import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import AvailabilityPage from './AvailabilityPage'

vi.mock('../../services/courier', () => ({
  getCourierProfile: vi.fn(),
  updateCourierAvailability: vi.fn(),
}))

import { getCourierProfile, updateCourierAvailability } from '../../services/courier'

const approvedProfile = {
  id: 'c1',
  full_name: 'Carlos Oliveira',
  approval_state: 'approved',
  operational_state: 'offline',
}

describe('Courier AvailabilityPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders operational state and allows toggling to available', async () => {
    getCourierProfile.mockResolvedValue(approvedProfile)
    updateCourierAvailability.mockResolvedValue({
      ...approvedProfile,
      operational_state: 'available',
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <AvailabilityPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText(/Status operacional atual/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /ficar disponível/i })).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /ficar disponível/i }))

    await waitFor(() => {
      expect(updateCourierAvailability).toHaveBeenCalledWith(true)
    })
  })

  it('disables button if courier is on_delivery', async () => {
    getCourierProfile.mockResolvedValue({
      ...approvedProfile,
      operational_state: 'on_delivery',
    })

    render(
      <MemoryRouter>
        <AvailabilityPage />
      </MemoryRouter>,
    )

    await screen.findByText(/Status operacional atual/i)
    expect(screen.getByText(/Finalize sua entrega atual antes de alterar disponibilidade/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /ficar disponível/i })).toBeDisabled()
  })

  it('disables button if courier is not approved', async () => {
    getCourierProfile.mockResolvedValue({
      ...approvedProfile,
      approval_state: 'pending_review',
    })

    render(
      <MemoryRouter>
        <AvailabilityPage />
      </MemoryRouter>,
    )

    await screen.findByText(/Status operacional atual/i)
    expect(screen.getByText(/Aguardando aprovação do admin/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /ficar disponível/i })).toBeDisabled()
  })
})

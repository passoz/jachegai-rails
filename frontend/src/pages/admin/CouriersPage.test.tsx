import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import CouriersPage from './CouriersPage'

vi.mock('../../services/adminModeration', () => ({
  listAdminCouriers: vi.fn(),
}))

import { listAdminCouriers } from '../../services/adminModeration'

const couriers = [
  { id: 'c1', full_name: 'Roberto Motoboy', vehicle_type: 'moto', approval_state: 'pending_review', operational_state: 'offline' },
]

describe('Admin CouriersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders couriers list', async () => {
    listAdminCouriers.mockResolvedValue(couriers)
    render(
      <MemoryRouter>
        <CouriersPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Roberto Motoboy')).toBeInTheDocument()
    expect(screen.getByText('moto')).toBeInTheDocument()
  })
})

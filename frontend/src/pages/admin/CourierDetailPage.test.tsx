import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import CourierDetailPage from './CourierDetailPage'

vi.mock('../../services/adminModeration', () => ({
  getAdminCourier: vi.fn(),
  approveAdminCourier: vi.fn(),
  rejectAdminCourier: vi.fn(),
  suspendAdminCourier: vi.fn(),
  reinstateAdminCourier: vi.fn(),
}))

import {
  getAdminCourier,
  approveAdminCourier,
} from '../../services/adminModeration'

const courier = {
  id: 'c100',
  full_name: 'Marcos Entregador',
  document: '98765432100',
  vehicle_type: 'moto',
  phone: '11988887777',
  approval_state: 'pending_review',
  operational_state: 'offline',
}

describe('Admin CourierDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders courier details and action buttons', async () => {
    getAdminCourier.mockResolvedValue(courier)
    render(
      <MemoryRouter initialEntries={['/admin/couriers/c100']}>
        <Routes>
          <Route path="/admin/couriers/:id" element={<CourierDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Marcos Entregador')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /aprovar entregador/i })).toBeInTheDocument()
  })

  it('approves courier', async () => {
    getAdminCourier.mockResolvedValue(courier)
    approveAdminCourier.mockResolvedValue({ ...courier, approval_state: 'approved' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/couriers/c100']}>
        <Routes>
          <Route path="/admin/couriers/:id" element={<CourierDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Marcos Entregador')
    await user.click(screen.getByRole('button', { name: /aprovar entregador/i }))

    await waitFor(() => {
      expect(approveAdminCourier).toHaveBeenCalledWith('c100')
    })
  })
})

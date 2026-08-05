import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import DashboardPage from './DashboardPage'

vi.mock('../../services/admin', () => ({
  getAdminDashboard: vi.fn(),
}))

import { getAdminDashboard } from '../../services/admin'

const dashboardData = {
  users_count: 120,
  active_sellers_count: 15,
  active_couriers_count: 8,
  orders_today_count: 45,
  open_tickets_count: 3,
  pending_payments_count: 2,
}

describe('Admin DashboardPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders dashboard metric cards', async () => {
    getAdminDashboard.mockResolvedValue(dashboardData)
    render(
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('120')).toBeInTheDocument()
    expect(screen.getByText('15')).toBeInTheDocument()
    expect(screen.getByText('45')).toBeInTheDocument()
  })
})

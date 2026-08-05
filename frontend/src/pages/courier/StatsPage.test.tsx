import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import StatsPage from './StatsPage'

vi.mock('../../services/courierDeliveries', () => ({
  getCourierStats: vi.fn(),
}))

import { getCourierStats } from '../../services/courierDeliveries'

const statsData = {
  total_deliveries: 15,
  total_earnings_cents: 15000,
  currency: 'BRL',
}

describe('Courier StatsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders stats metrics cards', async () => {
    getCourierStats.mockResolvedValue(statsData)
    render(
      <MemoryRouter>
        <StatsPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('15')).toBeInTheDocument()
    expect(screen.getByText(/150,00/)).toBeInTheDocument()
  })
})

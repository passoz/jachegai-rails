import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import ObservabilityPage from './ObservabilityPage'

vi.mock('../../services/adminSystem', () => ({
  getObservabilitySummary: vi.fn(),
  getObservabilityRequests: vi.fn(),
  getObservabilityOrders: vi.fn(),
  getObservabilityJobs: vi.fn(),
}))

import {
  getObservabilitySummary,
  getObservabilityRequests,
  getObservabilityOrders,
  getObservabilityJobs,
} from '../../services/adminSystem'

const summary = { requests_count: 1250, pending_orders_count: 5, outbox_jobs_count: 0 }
const requests = [{ id: 'r1', path: '/api/v1/public/sellers', method: 'GET', status: 200, duration_ms: 12 }]

describe('Admin ObservabilityPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders observability summary metrics and requests log', async () => {
    getObservabilitySummary.mockResolvedValue(summary)
    getObservabilityRequests.mockResolvedValue(requests)
    getObservabilityOrders.mockResolvedValue([])
    getObservabilityJobs.mockResolvedValue([])

    render(
      <MemoryRouter>
        <ObservabilityPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('/api/v1/public/sellers')).toBeInTheDocument()
    expect(screen.getByText('GET')).toBeInTheDocument()
  })
})

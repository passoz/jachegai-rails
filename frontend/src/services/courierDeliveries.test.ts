import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  getEligibleDeliveries,
  getActiveDelivery,
  getDeliveryHistory,
  acceptDelivery,
  pickupDelivery,
  completeDelivery,
  getCourierStats,
} from './courierDeliveries'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const delivery = {
  id: 'co1',
  order_state: 'ready',
  seller_name: 'Pizzaria Bella',
  total_cents: 4000,
  courier_fee_cents: 600,
  currency: 'BRL',
}

const statsData = {
  total_deliveries: 12,
  total_earnings_cents: 7200,
  currency: 'BRL',
}

describe('courierDeliveries service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('getEligibleDeliveries GETs /api/v1/courier/orders/eligible', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [delivery] } })
    const res = await getEligibleDeliveries()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/courier/orders/eligible')
    expect(res[0].id).toBe('co1')
  })

  it('getActiveDelivery GETs /api/v1/courier/orders/active', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: delivery } })
    const res = await getActiveDelivery()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/courier/orders/active')
    expect(res?.id).toBe('co1')
  })

  it('getDeliveryHistory GETs /api/v1/courier/orders/history', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [delivery] } })
    const res = await getDeliveryHistory()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/courier/orders/history')
    expect(res[0].id).toBe('co1')
  })

  it('acceptDelivery POSTs /api/v1/courier/orders/:id/accept with Idempotency-Key', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: delivery } })
    await acceptDelivery('co1')
    expect(mockPost).toHaveBeenCalledWith(
      '/api/v1/courier/orders/co1/accept',
      {},
      expect.objectContaining({ headers: expect.objectContaining({ 'Idempotency-Key': expect.any(String) }) }),
    )
  })

  it('pickupDelivery POSTs /api/v1/courier/orders/:id/pickup', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: delivery } })
    await pickupDelivery('co1')
    expect(mockPost).toHaveBeenCalledWith(
      '/api/v1/courier/orders/co1/pickup',
      {},
      expect.objectContaining({ headers: expect.objectContaining({ 'Idempotency-Key': expect.any(String) }) }),
    )
  })

  it('completeDelivery POSTs /api/v1/courier/orders/:id/deliver', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: delivery } })
    await completeDelivery('co1')
    expect(mockPost).toHaveBeenCalledWith(
      '/api/v1/courier/orders/co1/deliver',
      {},
      expect.objectContaining({ headers: expect.objectContaining({ 'Idempotency-Key': expect.any(String) }) }),
    )
  })

  it('getCourierStats GETs /api/v1/courier/stats', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: statsData } })
    const res = await getCourierStats()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/courier/stats')
    expect(res.total_deliveries).toBe(12)
  })
})

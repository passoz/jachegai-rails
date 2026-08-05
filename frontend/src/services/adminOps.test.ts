import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  listAdminOrders,
  cancelAdminOrder,
  confirmAdminPayment,
  transitionAdminTicket,
} from './adminOps'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const orderData = { id: 'ao1', status: 'pending', total_cents: 5000, currency: 'BRL', items: [] }
const paymentData = { id: 'pay1', order_id: 'ao1', amount_cents: 5000, status: 'pending', currency: 'BRL' }
const ticketData = { id: 'tk1', subject: 'Problema', status: 'open', messages: [] }

describe('adminOps service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listAdminOrders GETs /api/v1/admin/orders', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [orderData] } })
    const res = await listAdminOrders()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/orders', { params: undefined })
    expect(res[0].id).toBe('ao1')
  })

  it('cancelAdminOrder POSTs /api/v1/admin/orders/:id/cancel', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...orderData, status: 'cancelled' } } })
    await cancelAdminOrder('ao1', 'Cancelamento admin')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/orders/ao1/cancel', { reason: 'Cancelamento admin' })
  })

  it('confirmAdminPayment POSTs /api/v1/admin/payments/:id/confirm', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...paymentData, status: 'paid' } } })
    await confirmAdminPayment('pay1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/payments/pay1/confirm')
  })

  it('transitionAdminTicket POSTs /api/v1/admin/tickets/:id/:action', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...ticketData, status: 'in_progress' } } })
    await transitionAdminTicket('tk1', 'start_progress')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/tickets/tk1/start_progress')
  })
})

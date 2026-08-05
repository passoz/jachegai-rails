import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  listSellerOrders,
  getSellerOrder,
  acceptSellerOrder,
  rejectSellerOrder,
  preparingSellerOrder,
  readySellerOrder,
} from './sellerOrders'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const order = {
  id: 'so1',
  status: 'pending',
  total_cents: 5000,
  currency: 'BRL',
  items: [{ id: 'i1', name: 'Pizza', quantity: 1, price_cents: 5000 }],
}

describe('sellerOrders service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listSellerOrders GETs /api/v1/seller/orders', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [order] } })
    const res = await listSellerOrders({ status: 'pending' })
    expect(mockGet).toHaveBeenCalledWith('/api/v1/seller/orders', { params: { status: 'pending' } })
    expect(res[0].id).toBe('so1')
  })

  it('getSellerOrder GETs /api/v1/seller/orders/:id', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: order } })
    const res = await getSellerOrder('so1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/seller/orders/so1')
    expect(res.status).toBe('pending')
  })

  it('acceptSellerOrder POSTs /api/v1/seller/orders/:id/accept', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...order, status: 'accepted' } } })
    await acceptSellerOrder('so1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/orders/so1/accept')
  })

  it('rejectSellerOrder POSTs /api/v1/seller/orders/:id/reject with reason', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...order, status: 'rejected' } } })
    await rejectSellerOrder('so1', 'Sem estoque de ingredientes')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/orders/so1/reject', { reason: 'Sem estoque de ingredientes' })
  })

  it('preparingSellerOrder POSTs /api/v1/seller/orders/:id/preparing', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...order, status: 'preparing' } } })
    await preparingSellerOrder('so1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/orders/so1/preparing')
  })

  it('readySellerOrder POSTs /api/v1/seller/orders/:id/ready', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...order, status: 'ready' } } })
    await readySellerOrder('so1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/orders/so1/ready')
  })
})

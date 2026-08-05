import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  listAdminSellers,
  approveAdminSeller,
  rejectAdminSeller,
  listAdminCouriers,
  approveAdminCourier,
} from './adminModeration'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const sellerData = { id: 's1', name: 'Padaria Alfa', moderation_state: 'pending_review' }
const courierData = { id: 'c1', full_name: 'José Motoboy', approval_state: 'pending_review' }

describe('adminModeration service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listAdminSellers GETs /api/v1/admin/sellers', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [sellerData] } })
    const res = await listAdminSellers({ status: 'pending_review' })
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/sellers', { params: { status: 'pending_review' } })
    expect(res[0].name).toBe('Padaria Alfa')
  })

  it('approveAdminSeller POSTs /api/v1/admin/sellers/:id/approve', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...sellerData, moderation_state: 'approved' } } })
    await approveAdminSeller('s1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/sellers/s1/approve', {})
  })

  it('rejectAdminSeller POSTs /api/v1/admin/sellers/:id/reject with reason', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...sellerData, moderation_state: 'rejected' } } })
    await rejectAdminSeller('s1', 'Documento inválido')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/sellers/s1/reject', { reason: 'Documento inválido' })
  })

  it('listAdminCouriers GETs /api/v1/admin/couriers', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [courierData] } })
    const res = await listAdminCouriers()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/couriers', { params: undefined })
    expect(res[0].full_name).toBe('José Motoboy')
  })

  it('approveAdminCourier POSTs /api/v1/admin/couriers/:id/approve', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...courierData, approval_state: 'approved' } } })
    await approveAdminCourier('c1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/couriers/c1/approve', {})
  })
})

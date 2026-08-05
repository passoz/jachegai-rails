import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  submitSellerOnboarding,
  getSellerProfile,
  updateSellerProfile,
  getSellerSettings,
  updateSellerSettings,
} from './seller'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>
const mockPatch = api.patch as ReturnType<typeof vi.fn>

const sellerProfile = {
  id: 's1',
  name: 'Pizzaria Bella',
  slug: 'pizzaria-bella',
  description: 'A melhor pizza',
  moderation_state: 'approved',
}

const sellerSettings = {
  seller_id: 's1',
  auto_accept_orders: false,
}

describe('seller service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('submitSellerOnboarding POSTs /api/v1/seller/onboarding', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: sellerProfile } })
    const payload = { name: 'Pizzaria Bella', description: 'Top' }
    const res = await submitSellerOnboarding(payload)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/onboarding', payload)
    expect(res.name).toBe('Pizzaria Bella')
  })

  it('getSellerProfile GETs /api/v1/seller/profile', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: sellerProfile } })
    const res = await getSellerProfile()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/seller/profile')
    expect(res.moderation_state).toBe('approved')
  })

  it('updateSellerProfile PATCHes /api/v1/seller/profile', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: { ...sellerProfile, name: 'Nova Pizza' } } })
    const res = await updateSellerProfile({ name: 'Nova Pizza' })
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/seller/profile', { name: 'Nova Pizza' })
    expect(res.name).toBe('Nova Pizza')
  })

  it('getSellerSettings GETs /api/v1/seller/settings', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: sellerSettings } })
    const res = await getSellerSettings()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/seller/settings')
    expect(res.auto_accept_orders).toBe(false)
  })

  it('updateSellerSettings PATCHes /api/v1/seller/settings', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: { ...sellerSettings, auto_accept_orders: true } } })
    const res = await updateSellerSettings({ auto_accept_orders: true })
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/seller/settings', { auto_accept_orders: true })
    expect(res.auto_accept_orders).toBe(true)
  })
})

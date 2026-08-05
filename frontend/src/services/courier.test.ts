import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  submitCourierOnboarding,
  getCourierProfile,
  updateCourierProfile,
  updateCourierAvailability,
} from './courier'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>
const mockPatch = api.patch as ReturnType<typeof vi.fn>

const courierProfile = {
  id: 'c1',
  full_name: 'Carlos Entregador',
  document: '12345678900',
  vehicle_type: 'moto',
  phone: '11988888888',
  approval_state: 'approved',
  operational_state: 'available',
}

describe('courier service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('submitCourierOnboarding POSTs /api/v1/courier/onboarding', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: courierProfile } })
    const payload = { full_name: 'Carlos Entregador', vehicle_type: 'moto' }
    const res = await submitCourierOnboarding(payload)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/courier/onboarding', payload)
    expect(res.full_name).toBe('Carlos Entregador')
  })

  it('getCourierProfile GETs /api/v1/courier/profile', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: courierProfile } })
    const res = await getCourierProfile()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/courier/profile')
    expect(res.operational_state).toBe('available')
  })

  it('updateCourierProfile PATCHes /api/v1/courier/profile', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: { ...courierProfile, phone: '11977777777' } } })
    const res = await updateCourierProfile({ phone: '11977777777' })
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/courier/profile', { phone: '11977777777' })
    expect(res.phone).toBe('11977777777')
  })

  it('updateCourierAvailability PATCHes /api/v1/courier/availability', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: { ...courierProfile, operational_state: 'offline' } } })
    const res = await updateCourierAvailability(false)
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/courier/availability', { available: false })
    expect(res.operational_state).toBe('offline')
  })
})

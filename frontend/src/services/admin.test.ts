import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  getAdminDashboard,
  listAdminUsers,
  getAdminUser,
  disableAdminUser,
  enableAdminUser,
} from './admin'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const dashboardData = {
  users_count: 50,
  active_sellers_count: 10,
  active_couriers_count: 5,
  orders_today_count: 20,
  open_tickets_count: 2,
  pending_payments_count: 3,
}

const userData = {
  id: 'u1',
  name: 'Admin Master',
  email: 'admin@example.com',
  roles: ['admin'],
  active: true,
}

describe('admin service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('getAdminDashboard GETs /api/v1/admin/dashboard', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: dashboardData } })
    const res = await getAdminDashboard()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/dashboard')
    expect(res.users_count).toBe(50)
  })

  it('listAdminUsers GETs /api/v1/admin/users', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [userData] } })
    const res = await listAdminUsers()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/users', { params: undefined })
    expect(res[0].name).toBe('Admin Master')
  })

  it('getAdminUser GETs /api/v1/admin/users/:id', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: userData } })
    const res = await getAdminUser('u1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/users/u1')
    expect(res.id).toBe('u1')
  })

  it('disableAdminUser POSTs /api/v1/admin/users/:id/disable', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...userData, active: false } } })
    await disableAdminUser('u1', 'Violação dos termos')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/users/u1/disable', { reason: 'Violação dos termos' })
  })

  it('enableAdminUser POSTs /api/v1/admin/users/:id/enable', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...userData, active: true } } })
    await enableAdminUser('u1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/users/u1/enable')
  })
})

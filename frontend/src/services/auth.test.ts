import { describe, it, expect, vi, beforeEach } from 'vitest'
import * as authService from './auth'

vi.mock('./api', () => {
  return {
    default: {
      post: vi.fn(),
      get: vi.fn(),
    },
    unwrap: (response: { data: { data: unknown } }) => response.data.data,
  }
})

import api from './api'

const mockPost = api.post as ReturnType<typeof vi.fn>
const mockGet = api.get as ReturnType<typeof vi.fn>

describe('auth service', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('login posts to /api/v1/auth/login', async () => {
    mockPost.mockResolvedValue({
      data: { ok: true, data: { token: 't', user: { id: '1', email: 'a@b.com', name: 'A', roles: ['customer'] } }, meta: {} },
    })
    const result = await authService.login({ email: 'a@b.com', password: 'secret' })
    expect(mockPost).toHaveBeenCalledWith('/api/v1/auth/login', { email: 'a@b.com', password: 'secret' })
    expect(result.token).toBe('t')
    expect(result.user.email).toBe('a@b.com')
  })

  it('register posts to /api/v1/auth/register', async () => {
    mockPost.mockResolvedValue({
      data: { ok: true, data: { token: 't', user: { id: '1', email: 'a@b.com', name: 'A', roles: ['customer'] } }, meta: {} },
    })
    const result = await authService.register({ name: 'A', email: 'a@b.com', password: 'secret' })
    expect(mockPost).toHaveBeenCalledWith('/api/v1/auth/register', { name: 'A', email: 'a@b.com', password: 'secret' })
    expect(result.token).toBe('t')
  })

  it('logout posts to /api/v1/auth/logout', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: {}, meta: {} } })
    await authService.logout()
    expect(mockPost).toHaveBeenCalledWith('/api/v1/auth/logout')
  })

  it('logout does not throw on network error', async () => {
    mockPost.mockRejectedValue(new Error('network'))
    await expect(authService.logout()).resolves.toBeUndefined()
  })

  it('getMe gets /api/v1/auth/me', async () => {
    mockGet.mockResolvedValue({
      data: { ok: true, data: { id: '1', email: 'a@b.com', name: 'A', roles: ['customer'] }, meta: {} },
    })
    const user = await authService.getMe()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/auth/me')
    expect(user.roles).toContain('customer')
  })
})

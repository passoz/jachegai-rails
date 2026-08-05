import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  getCustomerProfile,
  updateCustomerProfile,
  listCustomerAddresses,
  createCustomerAddress,
  updateCustomerAddress,
  deleteCustomerAddress,
  setDefaultCustomerAddress,
  listCustomerFavorites,
  addCustomerFavorite,
  removeCustomerFavorite,
} from './customer'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>
const mockPatch = api.patch as ReturnType<typeof vi.fn>
const mockDelete = api.delete as ReturnType<typeof vi.fn>

const profile = { id: 'c1', name: 'João Silva', email: 'joao@example.com' }
const address = {
  id: 'a1',
  street: 'Rua das Flores',
  number: '123',
  neighborhood: 'Centro',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01000-000',
  default: true,
}
const favorite = { id: 'f1', seller_id: 's1', seller_name: 'Loja Top' }

describe('customer service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('getCustomerProfile GETs /api/v1/customer/profile', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: profile } })
    const res = await getCustomerProfile()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/profile')
    expect(res.name).toBe('João Silva')
  })

  it('updateCustomerProfile PATCHes /api/v1/customer/profile', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: { ...profile, name: 'Novo Nome' } } })
    const res = await updateCustomerProfile('Novo Nome')
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/customer/profile', { name: 'Novo Nome' })
    expect(res.name).toBe('Novo Nome')
  })

  it('listCustomerAddresses GETs /api/v1/customer/addresses', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [address] } })
    const res = await listCustomerAddresses()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/addresses')
    expect(res[0].street).toBe('Rua das Flores')
  })

  it('createCustomerAddress POSTs /api/v1/customer/addresses', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: address } })
    const payload = {
      street: 'Rua A',
      number: '1',
      neighborhood: 'B',
      city: 'C',
      state: 'SP',
      zip_code: '00000-000',
    }
    const res = await createCustomerAddress(payload)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/addresses', payload)
    expect(res.id).toBe('a1')
  })

  it('updateCustomerAddress PATCHes /api/v1/customer/addresses/:id', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: address } })
    await updateCustomerAddress('a1', { number: '456' })
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/customer/addresses/a1', { number: '456' })
  })

  it('deleteCustomerAddress DELETEs /api/v1/customer/addresses/:id', async () => {
    mockDelete.mockResolvedValue({ data: { ok: true, data: {} } })
    await deleteCustomerAddress('a1')
    expect(mockDelete).toHaveBeenCalledWith('/api/v1/customer/addresses/a1')
  })

  it('setDefaultCustomerAddress POSTs /api/v1/customer/addresses/:id/default', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: address } })
    await setDefaultCustomerAddress('a1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/addresses/a1/default')
  })

  it('listCustomerFavorites GETs /api/v1/customer/favorites', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [favorite] } })
    const res = await listCustomerFavorites()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/favorites')
    expect(res[0].seller_name).toBe('Loja Top')
  })

  it('addCustomerFavorite POSTs /api/v1/customer/favorites', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: favorite } })
    await addCustomerFavorite('s1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/favorites', { seller_id: 's1' })
  })

  it('removeCustomerFavorite DELETEs /api/v1/customer/favorites/:id', async () => {
    mockDelete.mockResolvedValue({ data: { ok: true, data: {} } })
    await removeCustomerFavorite('f1')
    expect(mockDelete).toHaveBeenCalledWith('/api/v1/customer/favorites/f1')
  })
})

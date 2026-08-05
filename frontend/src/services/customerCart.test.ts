import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  getCustomerCart,
  clearCustomerCart,
  addCustomerCartItem,
  updateCustomerCartItem,
  removeCustomerCartItem,
  handoffGuestCart,
  checkoutCustomerCart,
} from './customerCart'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>
const mockPatch = api.patch as ReturnType<typeof vi.fn>
const mockDelete = api.delete as ReturnType<typeof vi.fn>

const cartData = {
  items: [{ id: 'ci1', product_id: 'p1', name: 'Pizza', quantity: 2, price_cents: 2000, currency: 'BRL' }],
  subtotal_cents: 4000,
  delivery_fee_cents: 500,
  total_cents: 4500,
  currency: 'BRL',
}

describe('customerCart service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('getCustomerCart GETs /api/v1/customer/cart', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: cartData } })
    const res = await getCustomerCart()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/cart')
    expect(res.total_cents).toBe(4500)
  })

  it('clearCustomerCart DELETEs /api/v1/customer/cart', async () => {
    mockDelete.mockResolvedValue({ data: { ok: true, data: {} } })
    await clearCustomerCart()
    expect(mockDelete).toHaveBeenCalledWith('/api/v1/customer/cart')
  })

  it('addCustomerCartItem POSTs /api/v1/customer/cart/items', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: cartData } })
    await addCustomerCartItem('p1', 2)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/cart/items', { product_id: 'p1', quantity: 2 })
  })

  it('updateCustomerCartItem PATCHes /api/v1/customer/cart/items/:id', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: cartData } })
    await updateCustomerCartItem('ci1', 3)
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/customer/cart/items/ci1', { quantity: 3 })
  })

  it('removeCustomerCartItem DELETEs /api/v1/customer/cart/items/:id', async () => {
    mockDelete.mockResolvedValue({ data: { ok: true, data: cartData } })
    await removeCustomerCartItem('ci1')
    expect(mockDelete).toHaveBeenCalledWith('/api/v1/customer/cart/items/ci1')
  })

  it('handoffGuestCart POSTs /api/v1/customer/cart/handoff', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: cartData } })
    await handoffGuestCart()
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/cart/handoff')
  })

  it('checkoutCustomerCart POSTs /api/v1/customer/checkout', async () => {
    const orderResult = { id: 'o1', status: 'pending', total_cents: 4500 }
    mockPost.mockResolvedValue({ data: { ok: true, data: orderResult } })
    const res = await checkoutCustomerCart('addr1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/checkout', { address_id: 'addr1' })
    expect(res.id).toBe('o1')
  })
})

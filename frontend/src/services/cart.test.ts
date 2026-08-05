import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import { getCart, clearCart, addCartItem, updateCartItem, removeCartItem } from './cart'
import type { CartResponse } from './cart'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>
const mockPatch = api.patch as ReturnType<typeof vi.fn>
const mockDelete = api.delete as ReturnType<typeof vi.fn>

const cart: CartResponse = {
  items: [{ id: 'i1', product_id: 'p1', quantity: 2, name: 'Produto X', price_cents: 1250, currency: 'BRL' }],
  total_cents: 2500,
  currency: 'BRL',
}

describe('cart service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('getCart GETs /api/v1/public/cart', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: cart, meta: {} } })
    const result = await getCart()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/public/cart')
    expect(result.total_cents).toBe(2500)
  })

  it('clearCart DELETEs /api/v1/public/cart', async () => {
    mockDelete.mockResolvedValue({ data: { ok: true, data: {}, meta: {} } })
    await clearCart()
    expect(mockDelete).toHaveBeenCalledWith('/api/v1/public/cart')
  })

  it('addCartItem POSTs with product_id and quantity', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: cart, meta: {} } })
    const result = await addCartItem('p1', 3)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/public/cart/items', { product_id: 'p1', quantity: 3 })
    expect(result.items[0].quantity).toBe(2)
  })

  it('addCartItem sends replace_confirmed when confirmed', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: cart, meta: {} } })
    await addCartItem('p1', 1, true)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/public/cart/items', {
      product_id: 'p1',
      quantity: 1,
      replace_confirmed: true,
    })
  })

  it('updateCartItem PATCHes item with quantity', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: cart, meta: {} } })
    await updateCartItem('i1', 5)
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/public/cart/items/i1', { quantity: 5 })
  })

  it('removeCartItem DELETEs item', async () => {
    mockDelete.mockResolvedValue({ data: { ok: true, data: cart, meta: {} } })
    await removeCartItem('i1')
    expect(mockDelete).toHaveBeenCalledWith('/api/v1/public/cart/items/i1')
  })
})

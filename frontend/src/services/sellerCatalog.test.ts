import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), put: vi.fn(), delete: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  listSellerCategories,
  createSellerCategory,
  reorderSellerCategories,
  listSellerProducts,
  activateSellerProduct,
  deactivateSellerProduct,
  updateSellerInventory,
} from './sellerCatalog'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>
const mockPatch = api.patch as ReturnType<typeof vi.fn>
const mockPut = api.put as ReturnType<typeof vi.fn>

const category = { id: 'cat1', name: 'Bebidas', position: 1 }
const product = {
  id: 'p1',
  name: 'Coca Cola',
  price_cents: 800,
  currency: 'BRL',
  active: true,
  category_id: 'cat1',
}

describe('sellerCatalog service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listSellerCategories GETs /api/v1/seller/categories', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [category] } })
    const res = await listSellerCategories()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/seller/categories')
    expect(res[0].name).toBe('Bebidas')
  })

  it('createSellerCategory POSTs /api/v1/seller/categories', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: category } })
    await createSellerCategory('Bebidas')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/categories', { name: 'Bebidas' })
  })

  it('reorderSellerCategories PUTs /api/v1/seller/categories/order', async () => {
    mockPut.mockResolvedValue({ data: { ok: true, data: [category] } })
    await reorderSellerCategories(['cat1', 'cat2'])
    expect(mockPut).toHaveBeenCalledWith('/api/v1/seller/categories/order', { ids: ['cat1', 'cat2'] })
  })

  it('listSellerProducts GETs /api/v1/seller/products', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [product] } })
    const res = await listSellerProducts()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/seller/products')
    expect(res[0].name).toBe('Coca Cola')
  })

  it('activateSellerProduct POSTs /api/v1/seller/products/:id/activate', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: product } })
    await activateSellerProduct('p1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/products/p1/activate')
  })

  it('deactivateSellerProduct POSTs /api/v1/seller/products/:id/deactivate', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { ...product, active: false } } })
    await deactivateSellerProduct('p1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/seller/products/p1/deactivate')
  })

  it('updateSellerInventory PATCHes /api/v1/seller/inventory/:product_id', async () => {
    mockPatch.mockResolvedValue({ data: { ok: true, data: { product_id: 'p1', quantity: 20 } } })
    await updateSellerInventory('p1', 20)
    expect(mockPatch).toHaveBeenCalledWith('/api/v1/seller/inventory/p1', { quantity: 20 })
  })
})

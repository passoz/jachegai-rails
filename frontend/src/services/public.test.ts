import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import { listSellers, getSeller, listSellerProducts, getProduct } from './public'
import type { PublicSeller, PublicProduct } from '../types/public'

const mockGet = api.get as ReturnType<typeof vi.fn>

const seller: PublicSeller = {
  id: 's1',
  name: 'Loja Teste',
  slug: 'loja-teste',
  moderation_state: 'approved',
}

const product: PublicProduct = {
  id: 'p1',
  seller_id: 's1',
  name: 'Produto X',
  price_cents: 1250,
  currency: 'BRL',
  active: true,
}

describe('public service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listSellers GETs /api/v1/public/sellers', async () => {
    mockGet.mockResolvedValue({
      data: {
        ok: true,
        data: [seller],
        meta: { pagination: { page: 1, per_page: 10, total: 1, total_pages: 1 } },
      },
    })
    const result = await listSellers({ limit: 6 })
    expect(mockGet).toHaveBeenCalledWith('/api/v1/public/sellers', { params: { limit: 6 } })
    expect(result.sellers[0].name).toBe('Loja Teste')
    expect(result.pagination?.total_pages).toBe(1)
  })

  it('getSeller GETs /api/v1/public/sellers/:id', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: seller, meta: {} } })
    const result = await getSeller('s1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/public/sellers/s1')
    expect(result.slug).toBe('loja-teste')
  })

  it('listSellerProducts GETs /api/v1/public/sellers/:id/products', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [product], meta: {} } })
    const result = await listSellerProducts('s1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/public/sellers/s1/products')
    expect(result[0].name).toBe('Produto X')
  })

  it('getProduct GETs /api/v1/public/products/:id', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: product, meta: {} } })
    const result = await getProduct('p1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/public/products/p1')
    expect(result.price_cents).toBe(1250)
  })
})

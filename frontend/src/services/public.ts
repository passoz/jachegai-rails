import api, { unwrap } from './api'
import type { PublicSeller, PublicProduct } from '../types/public'

export interface Pagination {
  page: number
  per_page: number
  total: number
  total_pages: number
}

export interface ListSellersResult {
  sellers: PublicSeller[]
  pagination?: Pagination
}

export async function listSellers(params?: Record<string, unknown>): Promise<ListSellersResult> {
  const response = await api.get('/api/v1/public/sellers', { params })
  const data = unwrap<PublicSeller[]>(response)
  const pagination = (response.data as { meta?: { pagination?: Pagination } }).meta?.pagination
  return { sellers: data, pagination }
}

export async function getSeller(id: string): Promise<PublicSeller> {
  const response = await api.get(`/api/v1/public/sellers/${id}`)
  return unwrap<PublicSeller>(response)
}

export async function listSellerProducts(sellerId: string): Promise<PublicProduct[]> {
  const response = await api.get(`/api/v1/public/sellers/${sellerId}/products`)
  return unwrap<PublicProduct[]>(response)
}

export async function getProduct(id: string): Promise<PublicProduct> {
  const response = await api.get(`/api/v1/public/products/${id}`)
  return unwrap<PublicProduct>(response)
}

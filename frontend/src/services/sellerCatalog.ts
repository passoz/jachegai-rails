import api, { unwrap } from './api'

export interface SellerCategory {
  id: string
  name: string
  position: number
}

export interface SellerProduct {
  id: string
  seller_id?: string
  category_id?: string | null
  name: string
  description?: string | null
  price_cents: number
  currency: string
  active: boolean
  quantity?: number
  created_at?: string
}

export interface ProductPayload {
  name: string
  description?: string
  price_cents: number
  currency?: string
  category_id?: string
  active?: boolean
}

export async function listSellerCategories(): Promise<SellerCategory[]> {
  const response = await api.get('/api/v1/seller/categories')
  return unwrap<SellerCategory[]>(response)
}

export async function createSellerCategory(name: string): Promise<SellerCategory> {
  const response = await api.post('/api/v1/seller/categories', { name })
  return unwrap<SellerCategory>(response)
}

export async function updateSellerCategory(id: string, name: string): Promise<SellerCategory> {
  const response = await api.patch(`/api/v1/seller/categories/${id}`, { name })
  return unwrap<SellerCategory>(response)
}

export async function deleteSellerCategory(id: string): Promise<void> {
  await api.delete(`/api/v1/seller/categories/${id}`)
}

export async function reorderSellerCategories(ids: string[]): Promise<SellerCategory[]> {
  const response = await api.put('/api/v1/seller/categories/order', { ids })
  return unwrap<SellerCategory[]>(response)
}

export async function listSellerProducts(): Promise<SellerProduct[]> {
  const response = await api.get('/api/v1/seller/products')
  return unwrap<SellerProduct[]>(response)
}

export async function createSellerProduct(payload: ProductPayload): Promise<SellerProduct> {
  const response = await api.post('/api/v1/seller/products', payload)
  return unwrap<SellerProduct>(response)
}

export async function updateSellerProduct(
  id: string,
  payload: Partial<ProductPayload>,
): Promise<SellerProduct> {
  const response = await api.patch(`/api/v1/seller/products/${id}`, payload)
  return unwrap<SellerProduct>(response)
}

export async function deleteSellerProduct(id: string): Promise<void> {
  await api.delete(`/api/v1/seller/products/${id}`)
}

export async function activateSellerProduct(id: string): Promise<SellerProduct> {
  const response = await api.post(`/api/v1/seller/products/${id}/activate`)
  return unwrap<SellerProduct>(response)
}

export async function deactivateSellerProduct(id: string): Promise<SellerProduct> {
  const response = await api.post(`/api/v1/seller/products/${id}/deactivate`)
  return unwrap<SellerProduct>(response)
}

export async function updateSellerInventory(
  productId: string,
  quantity: number,
): Promise<{ product_id: string; quantity: number }> {
  const response = await api.patch(`/api/v1/seller/inventory/${productId}`, { quantity })
  return unwrap<{ product_id: string; quantity: number }>(response)
}

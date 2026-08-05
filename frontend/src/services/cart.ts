import api, { unwrap } from './api'
import type { PublicProduct } from '../types/public'

export interface CartItem {
  id: string
  product_id: string
  quantity: number
  product?: PublicProduct
  name?: string
  price_cents?: number
  currency?: string
  seller_id?: string
  seller_name?: string
  created_at?: string
}

export interface CartResponse {
  items: CartItem[]
  seller_id?: string | null
  seller_name?: string | null
  total_cents: number
  currency: string
}

export async function getCart(): Promise<CartResponse> {
  const response = await api.get('/api/v1/public/cart')
  return unwrap<CartResponse>(response)
}

export async function clearCart(): Promise<void> {
  await api.delete('/api/v1/public/cart')
}

export async function addCartItem(productId: string, quantity = 1, replaceConfirmed = false): Promise<CartResponse> {
  const response = await api.post('/api/v1/public/cart/items', {
    product_id: productId,
    quantity,
    ...(replaceConfirmed ? { replace_confirmed: true } : {}),
  })
  return unwrap<CartResponse>(response)
}

export async function updateCartItem(itemId: string, quantity: number): Promise<CartResponse> {
  const response = await api.patch(`/api/v1/public/cart/items/${itemId}`, { quantity })
  return unwrap<CartResponse>(response)
}

export async function removeCartItem(itemId: string): Promise<CartResponse> {
  const response = await api.delete(`/api/v1/public/cart/items/${itemId}`)
  return unwrap<CartResponse>(response)
}

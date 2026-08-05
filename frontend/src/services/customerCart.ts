import api, { unwrap } from './api'

export interface CustomerCartItem {
  id: string
  product_id: string
  name: string
  quantity: number
  price_cents: number
  currency: string
  seller_id?: string
  seller_name?: string
}

export interface CustomerCart {
  items: CustomerCartItem[]
  seller_id?: string | null
  seller_name?: string | null
  subtotal_cents: number
  delivery_fee_cents: number
  total_cents: number
  currency: string
}

export interface CheckoutResult {
  id: string
  status: string
  total_cents: number
  currency: string
}

export async function getCustomerCart(): Promise<CustomerCart> {
  const response = await api.get('/api/v1/customer/cart')
  return unwrap<CustomerCart>(response)
}

export async function clearCustomerCart(): Promise<void> {
  await api.delete('/api/v1/customer/cart')
}

export async function addCustomerCartItem(
  productId: string,
  quantity = 1,
): Promise<CustomerCart> {
  const response = await api.post('/api/v1/customer/cart/items', {
    product_id: productId,
    quantity,
  })
  return unwrap<CustomerCart>(response)
}

export async function updateCustomerCartItem(
  itemId: string,
  quantity: number,
): Promise<CustomerCart> {
  const response = await api.patch(`/api/v1/customer/cart/items/${itemId}`, { quantity })
  return unwrap<CustomerCart>(response)
}

export async function removeCustomerCartItem(itemId: string): Promise<CustomerCart> {
  const response = await api.delete(`/api/v1/customer/cart/items/${itemId}`)
  return unwrap<CustomerCart>(response)
}

export async function handoffGuestCart(): Promise<CustomerCart> {
  const response = await api.post('/api/v1/customer/cart/handoff')
  return unwrap<CustomerCart>(response)
}

export async function checkoutCustomerCart(addressId: string): Promise<CheckoutResult> {
  const response = await api.post('/api/v1/customer/checkout', { address_id: addressId })
  return unwrap<CheckoutResult>(response)
}

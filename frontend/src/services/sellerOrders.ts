import api, { unwrap } from './api'

export interface SellerOrderItem {
  id: string
  name: string
  quantity: number
  price_cents: number
  currency: string
}

export interface SellerOrderHistory {
  state: string
  at: string
  actor?: string
  reason?: string
}

export interface SellerOrder {
  id: string
  status: string
  customer_name?: string
  customer_email?: string
  subtotal_cents: number
  delivery_fee_cents: number
  total_cents: number
  currency: string
  items: SellerOrderItem[]
  history?: SellerOrderHistory[]
  created_at: string
}

export async function listSellerOrders(params?: Record<string, unknown>): Promise<SellerOrder[]> {
  const response = await api.get('/api/v1/seller/orders', { params })
  return unwrap<SellerOrder[]>(response)
}

export async function getSellerOrder(id: string): Promise<SellerOrder> {
  const response = await api.get(`/api/v1/seller/orders/${id}`)
  return unwrap<SellerOrder>(response)
}

export async function acceptSellerOrder(id: string): Promise<SellerOrder> {
  const response = await api.post(`/api/v1/seller/orders/${id}/accept`)
  return unwrap<SellerOrder>(response)
}

export async function rejectSellerOrder(id: string, reason: string): Promise<SellerOrder> {
  const response = await api.post(`/api/v1/seller/orders/${id}/reject`, { reason })
  return unwrap<SellerOrder>(response)
}

export async function preparingSellerOrder(id: string): Promise<SellerOrder> {
  const response = await api.post(`/api/v1/seller/orders/${id}/preparing`)
  return unwrap<SellerOrder>(response)
}

export async function readySellerOrder(id: string): Promise<SellerOrder> {
  const response = await api.post(`/api/v1/seller/orders/${id}/ready`)
  return unwrap<SellerOrder>(response)
}

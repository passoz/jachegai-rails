import api, { unwrap } from './api'

export interface CourierOrder {
  id: string
  order_state: string
  seller_id?: string
  seller_name?: string
  delivery_address?: string
  items_count?: number
  courier_fee_cents: number
  total_cents: number
  currency: string
  created_at?: string
}

export interface CourierStats {
  total_deliveries: number
  total_earnings_cents: number
  currency: string
}

function generateUuidV4(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

export async function getEligibleDeliveries(): Promise<CourierOrder[]> {
  const response = await api.get('/api/v1/courier/orders/eligible')
  return unwrap<CourierOrder[]>(response)
}

export async function getActiveDelivery(): Promise<CourierOrder | null> {
  const response = await api.get('/api/v1/courier/orders/active')
  return unwrap<CourierOrder | null>(response)
}

export async function getDeliveryHistory(): Promise<CourierOrder[]> {
  const response = await api.get('/api/v1/courier/orders/history')
  return unwrap<CourierOrder[]>(response)
}

export async function acceptDelivery(id: string): Promise<CourierOrder> {
  const response = await api.post(
    `/api/v1/courier/orders/${id}/accept`,
    {},
    { headers: { 'Idempotency-Key': generateUuidV4() } },
  )
  return unwrap<CourierOrder>(response)
}

export async function pickupDelivery(id: string): Promise<CourierOrder> {
  const response = await api.post(
    `/api/v1/courier/orders/${id}/pickup`,
    {},
    { headers: { 'Idempotency-Key': generateUuidV4() } },
  )
  return unwrap<CourierOrder>(response)
}

export async function completeDelivery(id: string): Promise<CourierOrder> {
  const response = await api.post(
    `/api/v1/courier/orders/${id}/deliver`,
    {},
    { headers: { 'Idempotency-Key': generateUuidV4() } },
  )
  return unwrap<CourierOrder>(response)
}

export async function getCourierStats(): Promise<CourierStats> {
  const response = await api.get('/api/v1/courier/stats')
  return unwrap<CourierStats>(response)
}

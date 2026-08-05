import api, { unwrap } from './api'

export interface OrderTrackingHistory {
  state: string
  at: string
  actor?: string
}

export interface CourierLocation {
  latitude: number
  longitude: number
  recorded_at: string
}

export interface OrderTracking {
  order_id: string
  order_state: string
  courier_location?: CourierLocation | null
  history: OrderTrackingHistory[]
}

export interface TicketMessage {
  id: string
  body: string
  sender: 'customer' | 'admin' | 'system'
  created_at: string
}

export interface CustomerTicket {
  id: string
  subject: string
  status: string
  order_id?: string | null
  created_at: string
  messages?: TicketMessage[]
}

export async function cancelCustomerOrder(orderId: string, reason: string): Promise<void> {
  await api.post(`/api/v1/customer/orders/${orderId}/cancel`, { reason })
}

export async function getCustomerOrderTracking(orderId: string): Promise<OrderTracking> {
  const response = await api.get(`/api/v1/customer/orders/${orderId}/tracking`)
  return unwrap<OrderTracking>(response)
}

export async function listCustomerTickets(): Promise<CustomerTicket[]> {
  const response = await api.get('/api/v1/customer/tickets')
  return unwrap<CustomerTicket[]>(response)
}

export async function getCustomerTicket(id: string): Promise<CustomerTicket> {
  const response = await api.get(`/api/v1/customer/tickets/${id}`)
  return unwrap<CustomerTicket>(response)
}

export async function createCustomerTicket(
  subject: string,
  message: string,
  orderId?: string,
): Promise<CustomerTicket> {
  const response = await api.post('/api/v1/customer/tickets', {
    subject,
    message,
    ...(orderId ? { order_id: orderId } : {}),
  })
  return unwrap<CustomerTicket>(response)
}

export async function addCustomerTicketMessage(
  ticketId: string,
  body: string,
): Promise<TicketMessage> {
  const response = await api.post(`/api/v1/customer/tickets/${ticketId}/messages`, { body })
  return unwrap<TicketMessage>(response)
}

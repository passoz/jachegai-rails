import api, { unwrap } from './api'
import type { SellerOrder } from './sellerOrders'
import type { CustomerTicket, TicketMessage } from './customerOrders'

export interface AdminPayment {
  id: string
  order_id: string
  amount_cents: number
  currency: string
  status: string
  payment_method?: string
  created_at?: string
}

export async function listAdminOrders(params?: Record<string, unknown>): Promise<SellerOrder[]> {
  const response = await api.get('/api/v1/admin/orders', { params })
  return unwrap<SellerOrder[]>(response)
}

export async function getAdminOrder(id: string): Promise<SellerOrder> {
  const response = await api.get(`/api/v1/admin/orders/${id}`)
  return unwrap<SellerOrder>(response)
}

export async function cancelAdminOrder(id: string, reason: string): Promise<SellerOrder> {
  const response = await api.post(`/api/v1/admin/orders/${id}/cancel`, { reason })
  return unwrap<SellerOrder>(response)
}

export async function listAdminPayments(params?: Record<string, unknown>): Promise<AdminPayment[]> {
  const response = await api.get('/api/v1/admin/payments', { params })
  return unwrap<AdminPayment[]>(response)
}

export async function getAdminPayment(id: string): Promise<AdminPayment> {
  const response = await api.get(`/api/v1/admin/payments/${id}`)
  return unwrap<AdminPayment>(response)
}

export async function confirmAdminPayment(id: string): Promise<AdminPayment> {
  const response = await api.post(`/api/v1/admin/payments/${id}/confirm`)
  return unwrap<AdminPayment>(response)
}

export async function listAdminTickets(params?: Record<string, unknown>): Promise<CustomerTicket[]> {
  const response = await api.get('/api/v1/admin/tickets', { params })
  return unwrap<CustomerTicket[]>(response)
}

export async function getAdminTicket(id: string): Promise<CustomerTicket> {
  const response = await api.get(`/api/v1/admin/tickets/${id}`)
  return unwrap<CustomerTicket>(response)
}

export async function addAdminTicketMessage(id: string, body: string): Promise<TicketMessage> {
  const response = await api.post(`/api/v1/admin/tickets/${id}/messages`, { body })
  return unwrap<TicketMessage>(response)
}

export async function transitionAdminTicket(
  id: string,
  action: 'start_progress' | 'resolve' | 'reopen' | 'close',
): Promise<CustomerTicket> {
  const response = await api.post(`/api/v1/admin/tickets/${id}/${action}`)
  return unwrap<CustomerTicket>(response)
}

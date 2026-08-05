import api, { unwrap } from './api'

export interface AdminDashboardMetrics {
  users_count: number
  active_sellers_count: number
  active_couriers_count: number
  orders_today_count: number
  open_tickets_count: number
  pending_payments_count: number
}

export interface AdminUser {
  id: string
  name: string
  email: string
  roles: string[]
  active: boolean
  created_at?: string
}

export async function getAdminDashboard(): Promise<AdminDashboardMetrics> {
  const response = await api.get('/api/v1/admin/dashboard')
  return unwrap<AdminDashboardMetrics>(response)
}

export async function listAdminUsers(params?: Record<string, unknown>): Promise<AdminUser[]> {
  const response = await api.get('/api/v1/admin/users', { params })
  return unwrap<AdminUser[]>(response)
}

export async function getAdminUser(id: string): Promise<AdminUser> {
  const response = await api.get(`/api/v1/admin/users/${id}`)
  return unwrap<AdminUser>(response)
}

export async function disableAdminUser(id: string, reason?: string): Promise<AdminUser> {
  const response = await api.post(`/api/v1/admin/users/${id}/disable`, { reason })
  return unwrap<AdminUser>(response)
}

export async function enableAdminUser(id: string): Promise<AdminUser> {
  const response = await api.post(`/api/v1/admin/users/${id}/enable`)
  return unwrap<AdminUser>(response)
}

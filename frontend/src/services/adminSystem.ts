import api, { unwrap } from './api'

export interface AdminInvoice {
  id: string
  seller_id: string
  seller_name?: string
  period_start?: string
  period_end?: string
  amount_cents: number
  currency: string
  created_at?: string
}

export interface AdminSetting {
  id?: string
  key: string
  value: string
  effective_from?: string
  created_at?: string
}

export interface ObservabilitySummary {
  requests_count?: number
  pending_orders_count?: number
  outbox_jobs_count?: number
  [key: string]: unknown
}

export interface ObservabilityRequest {
  id?: string
  path: string
  method: string
  status: number
  duration_ms: number
  created_at?: string
}

export async function listAdminInvoices(): Promise<AdminInvoice[]> {
  const response = await api.get('/api/v1/admin/invoices')
  return unwrap<AdminInvoice[]>(response)
}

export async function generateAdminInvoice(payload: {
  seller_id: string
  period_start: string
  period_end: string
}): Promise<AdminInvoice> {
  const response = await api.post('/api/v1/admin/invoices/generate', payload)
  return unwrap<AdminInvoice>(response)
}

export async function getAdminInvoice(id: string): Promise<AdminInvoice> {
  const response = await api.get(`/api/v1/admin/invoices/${id}`)
  return unwrap<AdminInvoice>(response)
}

export async function listAdminSettings(): Promise<AdminSetting[]> {
  const response = await api.get('/api/v1/admin/settings')
  return unwrap<AdminSetting[]>(response)
}

export async function createAdminSetting(payload: {
  key: string
  value: string
  effective_from?: string
}): Promise<AdminSetting> {
  const response = await api.post('/api/v1/admin/settings', payload)
  return unwrap<AdminSetting>(response)
}

export async function getObservabilitySummary(): Promise<ObservabilitySummary> {
  const response = await api.get('/api/v1/admin/observability/summary')
  return unwrap<ObservabilitySummary>(response)
}

export async function getObservabilityRequests(): Promise<ObservabilityRequest[]> {
  const response = await api.get('/api/v1/admin/observability/requests')
  return unwrap<ObservabilityRequest[]>(response)
}

export async function getObservabilityOrders(): Promise<unknown[]> {
  const response = await api.get('/api/v1/admin/observability/orders')
  return unwrap<unknown[]>(response)
}

export async function getObservabilityJobs(): Promise<unknown[]> {
  const response = await api.get('/api/v1/admin/observability/jobs')
  return unwrap<unknown[]>(response)
}

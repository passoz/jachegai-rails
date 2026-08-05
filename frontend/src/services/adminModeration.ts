import api, { unwrap } from './api'
import type { SellerProfile } from './seller'
import type { CourierProfile } from './courier'

export async function listAdminSellers(params?: Record<string, unknown>): Promise<SellerProfile[]> {
  const response = await api.get('/api/v1/admin/sellers', { params })
  return unwrap<SellerProfile[]>(response)
}

export async function getAdminSeller(id: string): Promise<SellerProfile> {
  const response = await api.get(`/api/v1/admin/sellers/${id}`)
  return unwrap<SellerProfile>(response)
}

export async function approveAdminSeller(id: string, reason?: string): Promise<SellerProfile> {
  const response = await api.post(`/api/v1/admin/sellers/${id}/approve`, { reason })
  return unwrap<SellerProfile>(response)
}

export async function rejectAdminSeller(id: string, reason: string): Promise<SellerProfile> {
  const response = await api.post(`/api/v1/admin/sellers/${id}/reject`, { reason })
  return unwrap<SellerProfile>(response)
}

export async function suspendAdminSeller(id: string, reason: string): Promise<SellerProfile> {
  const response = await api.post(`/api/v1/admin/sellers/${id}/suspend`, { reason })
  return unwrap<SellerProfile>(response)
}

export async function reinstateAdminSeller(id: string, reason?: string): Promise<SellerProfile> {
  const response = await api.post(`/api/v1/admin/sellers/${id}/reinstate`, { reason })
  return unwrap<SellerProfile>(response)
}

export async function listAdminCouriers(params?: Record<string, unknown>): Promise<CourierProfile[]> {
  const response = await api.get('/api/v1/admin/couriers', { params })
  return unwrap<CourierProfile[]>(response)
}

export async function getAdminCourier(id: string): Promise<CourierProfile> {
  const response = await api.get(`/api/v1/admin/couriers/${id}`)
  return unwrap<CourierProfile>(response)
}

export async function approveAdminCourier(id: string, reason?: string): Promise<CourierProfile> {
  const response = await api.post(`/api/v1/admin/couriers/${id}/approve`, { reason })
  return unwrap<CourierProfile>(response)
}

export async function rejectAdminCourier(id: string, reason: string): Promise<CourierProfile> {
  const response = await api.post(`/api/v1/admin/couriers/${id}/reject`, { reason })
  return unwrap<CourierProfile>(response)
}

export async function suspendAdminCourier(id: string, reason: string): Promise<CourierProfile> {
  const response = await api.post(`/api/v1/admin/couriers/${id}/suspend`, { reason })
  return unwrap<CourierProfile>(response)
}

export async function reinstateAdminCourier(id: string, reason?: string): Promise<CourierProfile> {
  const response = await api.post(`/api/v1/admin/couriers/${id}/reinstate`, { reason })
  return unwrap<CourierProfile>(response)
}

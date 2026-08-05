import api, { unwrap } from './api'

export interface SellerProfile {
  id: string
  name: string
  slug: string
  description?: string
  contact_email?: string
  contact_phone?: string
  address_line1?: string
  address_city?: string
  address_state?: string
  address_zip?: string
  address_country?: string
  moderation_state: 'pending_review' | 'approved' | 'suspended' | 'rejected' | string
  created_at?: string
}

export interface SellerSettings {
  seller_id?: string
  auto_accept_orders?: boolean
  notification_email?: string
  [key: string]: unknown
}

export interface SellerOnboardingPayload {
  name: string
  description?: string
  contact_email?: string
  contact_phone?: string
  address_line1?: string
  address_city?: string
  address_state?: string
  address_zip?: string
}

export async function submitSellerOnboarding(
  payload: SellerOnboardingPayload,
): Promise<SellerProfile> {
  const response = await api.post('/api/v1/seller/onboarding', payload)
  return unwrap<SellerProfile>(response)
}

export async function getSellerProfile(): Promise<SellerProfile> {
  const response = await api.get('/api/v1/seller/profile')
  return unwrap<SellerProfile>(response)
}

export async function updateSellerProfile(
  payload: Partial<SellerOnboardingPayload>,
): Promise<SellerProfile> {
  const response = await api.patch('/api/v1/seller/profile', payload)
  return unwrap<SellerProfile>(response)
}

export async function getSellerSettings(): Promise<SellerSettings> {
  const response = await api.get('/api/v1/seller/settings')
  return unwrap<SellerSettings>(response)
}

export async function updateSellerSettings(
  payload: Partial<SellerSettings>,
): Promise<SellerSettings> {
  const response = await api.patch('/api/v1/seller/settings', payload)
  return unwrap<SellerSettings>(response)
}

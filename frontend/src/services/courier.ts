import api, { unwrap } from './api'

export interface CourierProfile {
  id: string
  full_name: string
  document?: string
  vehicle_type: string
  phone?: string
  approval_state: 'pending_review' | 'approved' | 'suspended' | 'rejected' | string
  operational_state: 'offline' | 'available' | 'on_delivery' | string
  created_at?: string
}

export interface CourierOnboardingPayload {
  full_name: string
  document?: string
  vehicle_type: string
  phone?: string
}

export async function submitCourierOnboarding(
  payload: CourierOnboardingPayload,
): Promise<CourierProfile> {
  const response = await api.post('/api/v1/courier/onboarding', payload)
  return unwrap<CourierProfile>(response)
}

export async function getCourierProfile(): Promise<CourierProfile> {
  const response = await api.get('/api/v1/courier/profile')
  return unwrap<CourierProfile>(response)
}

export async function updateCourierProfile(
  payload: Partial<CourierOnboardingPayload>,
): Promise<CourierProfile> {
  const response = await api.patch('/api/v1/courier/profile', payload)
  return unwrap<CourierProfile>(response)
}

export async function updateCourierAvailability(available: boolean): Promise<CourierProfile> {
  const response = await api.patch('/api/v1/courier/availability', { available })
  return unwrap<CourierProfile>(response)
}

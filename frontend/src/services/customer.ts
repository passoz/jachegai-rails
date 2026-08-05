import api, { unwrap } from './api'
import type {
  CustomerProfile,
  CustomerAddress,
  AddressPayload,
  CustomerFavorite,
} from '../types/customer'

export async function getCustomerProfile(): Promise<CustomerProfile> {
  const response = await api.get('/api/v1/customer/profile')
  return unwrap<CustomerProfile>(response)
}

export async function updateCustomerProfile(name: string): Promise<CustomerProfile> {
  const response = await api.patch('/api/v1/customer/profile', { name })
  return unwrap<CustomerProfile>(response)
}

export async function listCustomerAddresses(): Promise<CustomerAddress[]> {
  const response = await api.get('/api/v1/customer/addresses')
  return unwrap<CustomerAddress[]>(response)
}

export async function createCustomerAddress(payload: AddressPayload): Promise<CustomerAddress> {
  const response = await api.post('/api/v1/customer/addresses', payload)
  return unwrap<CustomerAddress>(response)
}

export async function updateCustomerAddress(
  id: string,
  payload: Partial<AddressPayload>,
): Promise<CustomerAddress> {
  const response = await api.patch(`/api/v1/customer/addresses/${id}`, payload)
  return unwrap<CustomerAddress>(response)
}

export async function deleteCustomerAddress(id: string): Promise<void> {
  await api.delete(`/api/v1/customer/addresses/${id}`)
}

export async function setDefaultCustomerAddress(id: string): Promise<CustomerAddress> {
  const response = await api.post(`/api/v1/customer/addresses/${id}/default`)
  return unwrap<CustomerAddress>(response)
}

export async function listCustomerFavorites(): Promise<CustomerFavorite[]> {
  const response = await api.get('/api/v1/customer/favorites')
  return unwrap<CustomerFavorite[]>(response)
}

export async function addCustomerFavorite(sellerId: string): Promise<CustomerFavorite> {
  const response = await api.post('/api/v1/customer/favorites', { seller_id: sellerId })
  return unwrap<CustomerFavorite>(response)
}

export async function removeCustomerFavorite(id: string): Promise<void> {
  await api.delete(`/api/v1/customer/favorites/${id}`)
}

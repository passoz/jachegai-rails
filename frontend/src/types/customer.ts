export interface CustomerProfile {
  id: string
  name: string
  email: string
  created_at?: string
}

export interface CustomerAddress {
  id: string
  street: string
  number: string
  complement?: string | null
  neighborhood: string
  city: string
  state: string
  zip_code: string
  default: boolean
  created_at?: string
}

export interface AddressPayload {
  street: string
  number: string
  complement?: string
  neighborhood: string
  city: string
  state: string
  zip_code: string
}

export interface CustomerFavorite {
  id: string
  seller_id: string
  seller_name: string
  seller_slug?: string
  created_at?: string
}

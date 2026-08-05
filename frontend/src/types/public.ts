export interface PublicSeller {
  id: string
  name: string
  slug: string
  moderation_state: string
  description?: string
  contact_email?: string
  contact_phone?: string
  address_line1?: string
  address_city?: string
  address_state?: string
  address_zip?: string
  address_country?: string
  moderated_at?: string
  created_at?: string
}

export interface PublicProduct {
  id: string
  seller_id: string
  category_id?: string
  name: string
  description?: string
  price_cents: number
  currency: string
  active: boolean
  created_at?: string
}

export interface PaginationMeta {
  page?: number
  per_page?: number
  total?: number
  total_pages?: number
}

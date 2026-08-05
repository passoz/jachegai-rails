import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  listAdminInvoices,
  generateAdminInvoice,
  listAdminSettings,
  createAdminSetting,
  getObservabilitySummary,
} from './adminSystem'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const invoice = { id: 'inv1', seller_id: 's1', amount_cents: 12000, currency: 'BRL' }
const setting = { key: 'marketplace_fee_percent', value: '10' }

describe('adminSystem service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listAdminInvoices GETs /api/v1/admin/invoices', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [invoice] } })
    const res = await listAdminInvoices()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/invoices')
    expect(res[0].id).toBe('inv1')
  })

  it('generateAdminInvoice POSTs /api/v1/admin/invoices/generate', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: invoice } })
    const payload = { seller_id: 's1', period_start: '2026-08-01', period_end: '2026-08-05' }
    await generateAdminInvoice(payload)
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/invoices/generate', payload)
  })

  it('listAdminSettings GETs /api/v1/admin/settings', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [setting] } })
    const res = await listAdminSettings()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/settings')
    expect(res[0].key).toBe('marketplace_fee_percent')
  })

  it('createAdminSetting POSTs /api/v1/admin/settings', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: setting } })
    await createAdminSetting({ key: 'fee', value: '5' })
    expect(mockPost).toHaveBeenCalledWith('/api/v1/admin/settings', { key: 'fee', value: '5' })
  })

  it('getObservabilitySummary GETs /api/v1/admin/observability/summary', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: { requests_count: 500 } } })
    const res = await getObservabilitySummary()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/admin/observability/summary')
    expect(res.requests_count).toBe(500)
  })
})

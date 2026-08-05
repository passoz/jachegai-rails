import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import InvoiceDetailPage from './InvoiceDetailPage'

vi.mock('../../services/adminSystem', () => ({
  getAdminInvoice: vi.fn(),
}))

import { getAdminInvoice } from '../../services/adminSystem'

const invoice = {
  id: 'inv100',
  seller_id: 's1',
  seller_name: 'Padaria Alfa',
  period_start: '2026-08-01',
  period_end: '2026-08-05',
  amount_cents: 25000,
  currency: 'BRL',
}

describe('Admin InvoiceDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders invoice details', async () => {
    getAdminInvoice.mockResolvedValue(invoice)
    render(
      <MemoryRouter initialEntries={['/admin/invoices/inv100']}>
        <Routes>
          <Route path="/admin/invoices/:id" element={<InvoiceDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText(/Padaria Alfa/)).toBeInTheDocument()
    expect(screen.getByText(/250,00/)).toBeInTheDocument()
  })
})

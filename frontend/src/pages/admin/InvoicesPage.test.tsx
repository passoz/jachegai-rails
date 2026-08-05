import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import InvoicesPage from './InvoicesPage'

vi.mock('../../services/adminSystem', () => ({
  listAdminInvoices: vi.fn(),
  generateAdminInvoice: vi.fn(),
}))

vi.mock('../../services/adminModeration', () => ({
  listAdminSellers: vi.fn(),
}))

import { listAdminInvoices, generateAdminInvoice } from '../../services/adminSystem'
import { listAdminSellers } from '../../services/adminModeration'

const invoices = [
  { id: 'inv100', seller_id: 's1', seller_name: 'Padaria Alfa', amount_cents: 15000, currency: 'BRL' },
]

describe('Admin InvoicesPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders invoices list', async () => {
    listAdminInvoices.mockResolvedValue(invoices)
    listAdminSellers.mockResolvedValue([])

    render(
      <MemoryRouter>
        <InvoicesPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Padaria Alfa')).toBeInTheDocument()
    expect(screen.getByText(/150,00/)).toBeInTheDocument()
  })

  it('opens modal and generates new invoice', async () => {
    listAdminInvoices.mockResolvedValue(invoices)
    listAdminSellers.mockResolvedValue([{ id: 's1', name: 'Padaria Alfa', slug: 'padaria-alfa', moderation_state: 'approved' }])
    generateAdminInvoice.mockResolvedValue({ id: 'inv101', seller_id: 's1', amount_cents: 20000, currency: 'BRL' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <InvoicesPage />
      </MemoryRouter>,
    )

    await screen.findByText('Padaria Alfa')
    await user.click(screen.getByRole('button', { name: /gerar fatura/i }))

    expect(screen.getByRole('heading', { name: /gerar nova fatura/i })).toBeInTheDocument()

    await user.type(screen.getByLabelText(/início do período/i), '2026-08-01')
    await user.type(screen.getByLabelText(/fim do período/i), '2026-08-05')

    await user.click(screen.getByRole('button', { name: /^gerar$/i }))

    await waitFor(() => {
      expect(generateAdminInvoice).toHaveBeenCalledWith({
        seller_id: 's1',
        period_start: '2026-08-01',
        period_end: '2026-08-05',
      })
    })
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import PaymentDetailPage from './PaymentDetailPage'

vi.mock('../../services/adminOps', () => ({
  getAdminPayment: vi.fn(),
  confirmAdminPayment: vi.fn(),
}))

import { getAdminPayment, confirmAdminPayment } from '../../services/adminOps'

const payment = {
  id: 'pay100',
  order_id: 'o100',
  amount_cents: 8900,
  currency: 'BRL',
  status: 'pending',
}

describe('Admin PaymentDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders payment details and confirm button', async () => {
    getAdminPayment.mockResolvedValue(payment)
    render(
      <MemoryRouter initialEntries={['/admin/payments/pay100']}>
        <Routes>
          <Route path="/admin/payments/:id" element={<PaymentDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText(/#pay100/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /confirmar pagamento/i })).toBeInTheDocument()
  })

  it('confirms pending payment', async () => {
    getAdminPayment.mockResolvedValue(payment)
    confirmAdminPayment.mockResolvedValue({ ...payment, status: 'paid' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/payments/pay100']}>
        <Routes>
          <Route path="/admin/payments/:id" element={<PaymentDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText(/#pay100/i)
    await user.click(screen.getByRole('button', { name: /confirmar pagamento/i }))

    await waitFor(() => {
      expect(confirmAdminPayment).toHaveBeenCalledWith('pay100')
    })
  })
})

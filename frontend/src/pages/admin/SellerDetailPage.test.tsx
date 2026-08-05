import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import SellerDetailPage from './SellerDetailPage'

vi.mock('../../services/adminModeration', () => ({
  getAdminSeller: vi.fn(),
  approveAdminSeller: vi.fn(),
  rejectAdminSeller: vi.fn(),
  suspendAdminSeller: vi.fn(),
  reinstateAdminSeller: vi.fn(),
}))

import {
  getAdminSeller,
  approveAdminSeller,
  rejectAdminSeller,
} from '../../services/adminModeration'

const seller = {
  id: 's100',
  name: 'Loja Teste Moderação',
  slug: 'loja-teste',
  description: 'Vendemos alimentos',
  contact_phone: '11999999999',
  moderation_state: 'pending_review',
}

describe('Admin SellerDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders seller details and approve/reject buttons', async () => {
    getAdminSeller.mockResolvedValue(seller)
    render(
      <MemoryRouter initialEntries={['/admin/sellers/s100']}>
        <Routes>
          <Route path="/admin/sellers/:id" element={<SellerDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByText('Loja Teste Moderação')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /aprovar loja/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /rejeitar loja/i })).toBeInTheDocument()
  })

  it('approves seller', async () => {
    getAdminSeller.mockResolvedValue(seller)
    approveAdminSeller.mockResolvedValue({ ...seller, moderation_state: 'approved' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/sellers/s100']}>
        <Routes>
          <Route path="/admin/sellers/:id" element={<SellerDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Loja Teste Moderação')
    await user.click(screen.getByRole('button', { name: /aprovar loja/i }))

    await waitFor(() => {
      expect(approveAdminSeller).toHaveBeenCalledWith('s100')
    })
  })

  it('rejects seller with reason modal', async () => {
    getAdminSeller.mockResolvedValue(seller)
    rejectAdminSeller.mockResolvedValue({ ...seller, moderation_state: 'rejected' })
    const user = userEvent.setup()

    render(
      <MemoryRouter initialEntries={['/admin/sellers/s100']}>
        <Routes>
          <Route path="/admin/sellers/:id" element={<SellerDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await screen.findByText('Loja Teste Moderação')
    await user.click(screen.getByRole('button', { name: /rejeitar loja/i }))

    expect(screen.getByText(/Rejeitar loja\?/i)).toBeInTheDocument()
    await user.type(screen.getByLabelText(/motivo/i), 'CNPJ inconsistente')

    const confirmBtns = screen.getAllByRole('button', { name: /rejeitar/i })
    await user.click(confirmBtns[confirmBtns.length - 1])

    await waitFor(() => {
      expect(rejectAdminSeller).toHaveBeenCalledWith('s100', 'CNPJ inconsistente')
    })
  })
})

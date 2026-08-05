import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import SettingsPage from './SettingsPage'

vi.mock('../../services/seller', () => ({
  getSellerSettings: vi.fn(),
  updateSellerSettings: vi.fn(),
}))

import { getSellerSettings, updateSellerSettings } from '../../services/seller'

const settings = {
  seller_id: 's1',
  auto_accept_orders: false,
  notification_email: 'loja@example.com',
}

describe('Seller SettingsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders settings form', async () => {
    getSellerSettings.mockResolvedValue(settings)
    render(
      <MemoryRouter>
        <SettingsPage />
      </MemoryRouter>,
    )
    expect(await screen.findByDisplayValue('loja@example.com')).toBeInTheDocument()
  })

  it('updates settings on save', async () => {
    getSellerSettings.mockResolvedValue(settings)
    updateSellerSettings.mockResolvedValue({ ...settings, notification_email: 'nova@example.com' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <SettingsPage />
      </MemoryRouter>,
    )

    const input = await screen.findByDisplayValue('loja@example.com')
    await user.clear(input)
    await user.type(input, 'nova@example.com')

    await user.click(screen.getByRole('button', { name: /salvar/i }))

    await waitFor(() => {
      expect(updateSellerSettings).toHaveBeenCalledWith(
        expect.objectContaining({ notification_email: 'nova@example.com' }),
      )
    })
  })
})

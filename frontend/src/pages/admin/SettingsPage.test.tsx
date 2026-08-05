import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import SettingsPage from './SettingsPage'

vi.mock('../../services/adminSystem', () => ({
  listAdminSettings: vi.fn(),
  createAdminSetting: vi.fn(),
}))

import { listAdminSettings, createAdminSetting } from '../../services/adminSystem'

const settingsList = [{ id: 'set1', key: 'marketplace_fee_percent', value: '10' }]

describe('Admin SettingsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders settings list and adds new setting', async () => {
    listAdminSettings.mockResolvedValue(settingsList)
    createAdminSetting.mockResolvedValue({ id: 'set2', key: 'marketplace_fee_percent', value: '12' })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <SettingsPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('marketplace_fee_percent')).toBeInTheDocument()
    expect(screen.getByText('10')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /nova configuração/i }))

    await user.type(screen.getByLabelText(/valor/i), '12')
    await user.click(screen.getByRole('button', { name: /^salvar$/i }))

    await waitFor(() => {
      expect(createAdminSetting).toHaveBeenCalledWith(
        expect.objectContaining({ key: 'marketplace_fee_percent', value: '12' }),
      )
    })
  })
})

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import InventoryPage from './InventoryPage'

vi.mock('../../services/sellerCatalog', () => ({
  listSellerProducts: vi.fn(),
  updateSellerInventory: vi.fn(),
}))

import { listSellerProducts, updateSellerInventory } from '../../services/sellerCatalog'

const products = [
  {
    id: 'p1',
    name: 'Suco de Laranja',
    price_cents: 1000,
    currency: 'BRL',
    active: true,
    quantity: 15,
  },
]

describe('InventoryPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders products inventory and updates quantity', async () => {
    listSellerProducts.mockResolvedValue(products)
    updateSellerInventory.mockResolvedValue({ product_id: 'p1', quantity: 25 })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <InventoryPage />
      </MemoryRouter>,
    )

    expect(await screen.findByText('Suco de Laranja')).toBeInTheDocument()
    const input = screen.getByDisplayValue('15')
    await user.clear(input)
    await user.type(input, '25')

    await user.click(screen.getByRole('button', { name: /atualizar/i }))

    await waitFor(() => {
      expect(updateSellerInventory).toHaveBeenCalledWith('p1', 25)
    })
  })
})

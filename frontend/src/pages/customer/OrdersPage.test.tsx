import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import OrdersPage from './OrdersPage'

describe('OrdersPage', () => {
  it('renders order search input and navigation', async () => {
    const user = userEvent.setup()
    render(
      <MemoryRouter>
        <OrdersPage />
      </MemoryRouter>,
    )

    expect(screen.getByText(/Acompanhar pedido/i)).toBeInTheDocument()
    const input = screen.getByPlaceholderText(/Digite o código do pedido/i)
    await user.type(input, 'o12345')
    expect(input).toHaveValue('o12345')
    expect(screen.getByRole('button', { name: /ver tracking/i })).toBeInTheDocument()
  })
})

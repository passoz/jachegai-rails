import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import AddressesPage from './AddressesPage'

vi.mock('../../services/customer', () => ({
  listCustomerAddresses: vi.fn(),
  createCustomerAddress: vi.fn(),
  updateCustomerAddress: vi.fn(),
  deleteCustomerAddress: vi.fn(),
  setDefaultCustomerAddress: vi.fn(),
}))

import {
  listCustomerAddresses,
  createCustomerAddress,
  deleteCustomerAddress,
  setDefaultCustomerAddress,
} from '../../services/customer'

const addresses = [
  {
    id: 'a1',
    street: 'Rua das Flores',
    number: '123',
    complement: 'Apto 45',
    neighborhood: 'Centro',
    city: 'São Paulo',
    state: 'SP',
    zip_code: '01000-000',
    default: true,
  },
  {
    id: 'a2',
    street: 'Av Paulista',
    number: '1000',
    neighborhood: 'Bela Vista',
    city: 'São Paulo',
    state: 'SP',
    zip_code: '01310-000',
    default: false,
  },
]

describe('AddressesPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders addresses list with default badge', async () => {
    listCustomerAddresses.mockResolvedValue(addresses)
    render(
      <MemoryRouter>
        <AddressesPage />
      </MemoryRouter>,
    )
    expect(await screen.findByText(/Rua das Flores/)).toBeInTheDocument()
    expect(screen.getByText(/Av Paulista/)).toBeInTheDocument()
    expect(screen.getByText('Padrão')).toBeInTheDocument()
  })

  it('opens modal and creates new address', async () => {
    listCustomerAddresses.mockResolvedValue(addresses)
    createCustomerAddress.mockResolvedValue({
      id: 'a3',
      street: 'Rua Nova',
      number: '99',
      neighborhood: 'Bairro Novo',
      city: 'Campinas',
      state: 'SP',
      zip_code: '13000-000',
      default: false,
    })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <AddressesPage />
      </MemoryRouter>,
    )

    await screen.findByText(/Rua das Flores/)
    await user.click(screen.getByRole('button', { name: /novo endereço/i }))

    expect(screen.getByRole('heading', { name: /novo endereço/i })).toBeInTheDocument()

    await user.type(screen.getByLabelText(/rua/i), 'Rua Nova')
    await user.type(screen.getByLabelText(/número/i), '99')
    await user.type(screen.getByLabelText(/bairro/i), 'Bairro Novo')
    await user.type(screen.getByLabelText(/cidade/i), 'Campinas')
    await user.type(screen.getByLabelText(/estado/i), 'SP')
    await user.type(screen.getByLabelText(/cep/i), '13000-000')

    await user.click(screen.getByRole('button', { name: /salvar endereço/i }))

    await waitFor(() => {
      expect(createCustomerAddress).toHaveBeenCalledWith({
        street: 'Rua Nova',
        number: '99',
        complement: '',
        neighborhood: 'Bairro Novo',
        city: 'Campinas',
        state: 'SP',
        zip_code: '13000-000',
      })
    })
  })

  it('sets address as default', async () => {
    listCustomerAddresses.mockResolvedValue(addresses)
    setDefaultCustomerAddress.mockResolvedValue({ ...addresses[1], default: true })
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <AddressesPage />
      </MemoryRouter>,
    )

    await screen.findByText(/Av Paulista/)
    await user.click(screen.getByRole('button', { name: /tornar padrão/i }))

    await waitFor(() => {
      expect(setDefaultCustomerAddress).toHaveBeenCalledWith('a2')
    })
  })

  it('deletes address with confirm dialog', async () => {
    listCustomerAddresses.mockResolvedValue(addresses)
    deleteCustomerAddress.mockResolvedValue(undefined)
    const user = userEvent.setup()

    render(
      <MemoryRouter>
        <AddressesPage />
      </MemoryRouter>,
    )

    await screen.findByText(/Av Paulista/)
    const deleteBtns = screen.getAllByRole('button', { name: /excluir/i })
    await user.click(deleteBtns[0])

    expect(screen.getByText(/Excluir endereço?/i)).toBeInTheDocument()
    const modalButtons = screen.getAllByRole('button', { name: /excluir/i })
    await user.click(modalButtons[modalButtons.length - 1])

    await waitFor(() => {
      expect(deleteCustomerAddress).toHaveBeenCalledWith('a2')
    })
  })
})

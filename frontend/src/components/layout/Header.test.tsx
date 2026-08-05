import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import Header from './Header'
import { AuthContext, type AuthContextValue } from '../../contexts/authContext'

function renderWithAuth(value: Partial<AuthContextValue>) {
  const authValue: AuthContextValue = {
    user: null,
    token: null,
    loading: false,
    isAuthenticated: false,
    login: vi.fn(),
    register: vi.fn(),
    logout: vi.fn(),
    hasRole: () => false,
    ...value,
  }

  return render(
    <AuthContext.Provider value={authValue}>
      <MemoryRouter>
        <Routes>
          <Route path="/" element={<Header />} />
          <Route path="/login" element={<div>Login Page</div>} />
        </Routes>
      </MemoryRouter>
    </AuthContext.Provider>,
  )
}

describe('Header', () => {
  it('shows Entrar and Cadastrar for visitor', () => {
    renderWithAuth({})
    expect(screen.getByRole('link', { name: 'Entrar' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Cadastrar' })).toBeInTheDocument()
  })

  it('shows admin links for admin user', () => {
    renderWithAuth({
      user: { id: '1', email: 'a@b.com', name: 'Admin', roles: ['admin'] },
      isAuthenticated: true,
      hasRole: (r) => r === 'admin',
    })
    expect(screen.getByRole('link', { name: 'Dashboard' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Usuários' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Sellers' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Sair' })).toBeInTheDocument()
  })

  it('shows seller links for seller user', () => {
    renderWithAuth({
      user: { id: '1', email: 's@b.com', name: 'Seller', roles: ['seller'] },
      isAuthenticated: true,
      hasRole: (r) => r === 'seller',
    })
    expect(screen.getByRole('link', { name: 'Produtos' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Pedidos' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Estoque' })).toBeInTheDocument()
  })

  it('shows courier links for courier user', () => {
    renderWithAuth({
      user: { id: '1', email: 'c@b.com', name: 'Courier', roles: ['courier'] },
      isAuthenticated: true,
      hasRole: (r) => r === 'courier',
    })
    expect(screen.getByRole('link', { name: 'Entregas' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Disponibilidade' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Estatísticas' })).toBeInTheDocument()
  })

  it('shows customer links for customer user', () => {
    renderWithAuth({
      user: { id: '1', email: 'u@b.com', name: 'Customer', roles: ['customer'] },
      isAuthenticated: true,
      hasRole: (r) => r === 'customer',
    })
    expect(screen.getByRole('link', { name: 'Meus pedidos' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Carrinho' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Perfil' })).toBeInTheDocument()
  })

  it('calls logout and navigates to / on Sair click', async () => {
    const logout = vi.fn()
    renderWithAuth({
      user: { id: '1', email: 'u@b.com', name: 'Customer', roles: ['customer'] },
      isAuthenticated: true,
      hasRole: (r) => r === 'customer',
      logout,
    })
    await userEvent.click(screen.getByRole('button', { name: 'Sair' }))
    expect(logout).toHaveBeenCalledTimes(1)
  })
})

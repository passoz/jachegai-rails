import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import ProtectedRoute from './ProtectedRoute'
import { AuthContext, type AuthContextValue } from '../../contexts/authContext'

function renderProtected(overrides: Partial<AuthContextValue>) {
  const value: AuthContextValue = {
    user: null,
    token: null,
    loading: false,
    isAuthenticated: false,
    login: vi.fn(),
    register: vi.fn(),
    logout: vi.fn(),
    hasRole: () => false,
    ...overrides,
  }

  return render(
    <AuthContext.Provider value={value}>
      <MemoryRouter initialEntries={['/protected']}>
        <Routes>
          <Route element={<ProtectedRoute roles={['customer']} />}>
            <Route path="/protected" element={<div>Protected Content</div>} />
          </Route>
          <Route path="/login" element={<div>Login Page</div>} />
        </Routes>
      </MemoryRouter>
    </AuthContext.Provider>,
  )
}

describe('ProtectedRoute', () => {
  it('shows loading spinner while loading', () => {
    renderProtected({ loading: true })
    expect(screen.getByText('Carregando...')).toBeInTheDocument()
  })

  it('redirects to /login when not authenticated', async () => {
    renderProtected({})
    expect(screen.getByText('Login Page')).toBeInTheDocument()
  })

  it('renders protected content when authenticated with correct role', () => {
    renderProtected({
      user: { id: '1', email: 'a@b.com', name: 'A', roles: ['customer'] },
      token: 't',
      isAuthenticated: true,
      hasRole: (r) => r === 'customer',
    })
    expect(screen.getByText('Protected Content')).toBeInTheDocument()
  })

  it('shows access denied when authenticated but wrong role', () => {
    renderProtected({
      user: { id: '1', email: 's@b.com', name: 'S', roles: ['seller'] },
      token: 't',
      isAuthenticated: true,
      hasRole: (r) => r === 'seller',
    })
    expect(screen.getByText('Acesso negado')).toBeInTheDocument()
  })
})

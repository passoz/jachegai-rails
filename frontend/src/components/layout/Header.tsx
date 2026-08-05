import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../contexts/useAuth'

interface NavLink {
  label: string
  to: string
}

function linksForRole(role: string | null): NavLink[] {
  switch (role) {
    case 'admin':
      return [
        { label: 'Dashboard', to: '/admin/dashboard' },
        { label: 'Usuários', to: '/admin/users' },
        { label: 'Sellers', to: '/admin/sellers' },
        { label: 'Couriers', to: '/admin/couriers' },
        { label: 'Pedidos', to: '/admin/orders' },
        { label: 'Pagamentos', to: '/admin/payments' },
        { label: 'Tickets', to: '/admin/tickets' },
        { label: 'Faturas', to: '/admin/invoices' },
        { label: 'Config', to: '/admin/settings' },
      ]
    case 'seller':
      return [
        { label: 'Produtos', to: '/seller/products' },
        { label: 'Pedidos', to: '/seller/orders' },
        { label: 'Estoque', to: '/seller/inventory' },
        { label: 'Categorias', to: '/seller/categories' },
        { label: 'Perfil', to: '/seller/profile' },
      ]
    case 'courier':
      return [
        { label: 'Entregas', to: '/courier/deliveries' },
        { label: 'Histórico', to: '/courier/history' },
        { label: 'Disponibilidade', to: '/courier/availability' },
        { label: 'Estatísticas', to: '/courier/stats' },
        { label: 'Perfil', to: '/courier/profile' },
      ]
    case 'customer':
      return [
        { label: 'Meus pedidos', to: '/customer/orders' },
        { label: 'Carrinho', to: '/customer/cart' },
        { label: 'Endereços', to: '/customer/addresses' },
        { label: 'Favoritos', to: '/customer/favorites' },
        { label: 'Tickets', to: '/customer/tickets' },
        { label: 'Perfil', to: '/customer/profile' },
      ]
    default:
      return []
  }
}

export default function Header() {
  const { user, isAuthenticated, logout } = useAuth()
  const navigate = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)

  const role = user?.roles.find((r) => ['admin', 'seller', 'courier', 'customer'].includes(r)) ?? null
  const navLinks = linksForRole(role)

  const handleLogout = async () => {
    await logout()
    navigate('/')
  }

  return (
    <header className="border-b-4 border-brutal-black bg-white sticky top-0 z-40">
      <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between gap-4">
        <Link to={role === 'admin' ? '/admin/dashboard' : '/'} className="font-black italic text-2xl text-brutal-black">
          <span className="text-brutal-red">Ja</span>Chegai
        </Link>

        {/* Desktop nav */}
        {isAuthenticated && navLinks.length > 0 ? (
          <nav className="hidden md:flex items-center gap-1" aria-label="Navegação principal">
            {navLinks.map((link) => (
              <Link
                key={link.to}
                to={link.to}
                className="px-3 py-2 text-sm font-bold text-brutal-black hover:bg-brutal-red hover:text-white rounded-xl transition-colors"
              >
                {link.label}
              </Link>
            ))}
            <button
              type="button"
              onClick={handleLogout}
              className="ml-2 px-4 py-2 text-sm font-bold border-2 border-brutal-black rounded-xl hover:bg-brutal-black hover:text-white transition-colors cursor-pointer"
            >
              Sair
            </button>
          </nav>
        ) : (
          <nav className="hidden md:flex items-center gap-2" aria-label="Navegação visitante">
            <Link
              to="/login"
              className="px-4 py-2 text-sm font-bold border-2 border-brutal-black rounded-xl hover:bg-brutal-gray transition-colors"
            >
              Entrar
            </Link>
            <Link
              to="/register"
              className="px-4 py-2 text-sm font-bold bg-brutal-black text-white rounded-xl hover:bg-brutal-red hover:text-black transition-colors"
            >
              Cadastrar
            </Link>
          </nav>
        )}

        {/* Mobile hamburger */}
        <button
          type="button"
          className="md:hidden w-10 h-10 border-2 border-brutal-black rounded-xl flex flex-col items-center justify-center gap-1.5 cursor-pointer bg-white"
          onClick={() => setMenuOpen((v) => !v)}
          aria-label="Abrir menu"
        >
          <span className="w-5 h-0.5 bg-brutal-black" />
          <span className="w-5 h-0.5 bg-brutal-black" />
          <span className="w-5 h-0.5 bg-brutal-black" />
        </button>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden border-t-4 border-brutal-black bg-white px-6 py-4 flex flex-col gap-1">
          {isAuthenticated && navLinks.length > 0 ? (
            <>
              {navLinks.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  onClick={() => setMenuOpen(false)}
                  className="px-3 py-3 text-base font-bold text-brutal-black border-b-2 border-black/10 hover:bg-brutal-gray"
                >
                  {link.label}
                </Link>
              ))}
              <button
                type="button"
                onClick={handleLogout}
                className="mt-2 px-3 py-3 text-base font-bold border-2 border-brutal-black rounded-xl hover:bg-brutal-black hover:text-white transition-colors cursor-pointer"
              >
                Sair
              </button>
            </>
          ) : (
            <>
              <Link
                to="/login"
                onClick={() => setMenuOpen(false)}
                className="px-3 py-3 text-base font-bold border-2 border-brutal-black rounded-xl hover:bg-brutal-gray"
              >
                Entrar
              </Link>
              <Link
                to="/register"
                onClick={() => setMenuOpen(false)}
                className="px-3 py-3 text-base font-bold bg-brutal-black text-white rounded-xl hover:bg-brutal-red"
              >
                Cadastrar
              </Link>
            </>
          )}
        </div>
      )}
    </header>
  )
}

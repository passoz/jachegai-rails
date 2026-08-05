import { NavLink, Outlet } from 'react-router-dom'
import Header from './Header'
import Footer from './Footer'

const adminNav = [
  { label: 'Dashboard', to: '/admin/dashboard' },
  { label: 'Usuários', to: '/admin/users' },
  { label: 'Sellers', to: '/admin/sellers' },
  { label: 'Couriers', to: '/admin/couriers' },
  { label: 'Pedidos', to: '/admin/orders' },
  { label: 'Pagamentos', to: '/admin/payments' },
  { label: 'Tickets', to: '/admin/tickets' },
  { label: 'Faturas', to: '/admin/invoices' },
  { label: 'Config', to: '/admin/settings' },
  { label: 'Observabilidade', to: '/admin/observability' },
]

export default function AdminLayout() {
  return (
    <div className="min-h-screen flex flex-col bg-brutal-white">
      <Header />
      <div className="flex-1 flex">
        <aside className="hidden md:block w-60 shrink-0 border-r-4 border-brutal-black bg-brutal-black">
          <nav className="sticky top-[73px] py-6 px-4 flex flex-col gap-1" aria-label="Navegação admin">
            {adminNav.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  [
                    'px-3 py-2.5 text-sm font-bold rounded-xl transition-colors',
                    isActive
                      ? 'bg-brutal-red text-brutal-black'
                      : 'text-white hover:bg-white/10',
                  ].join(' ')
                }
              >
                {item.label}
              </NavLink>
            ))}
          </nav>
        </aside>
        <main className="flex-1 max-w-6xl w-full px-6 py-8">
          <Outlet />
        </main>
      </div>
      <Footer />
    </div>
  )
}

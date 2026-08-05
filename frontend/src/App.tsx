import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import PublicLayout from './components/layout/PublicLayout'
import CustomerLayout from './components/layout/CustomerLayout'
import SellerLayout from './components/layout/SellerLayout'
import CourierLayout from './components/layout/CourierLayout'
import AdminLayout from './components/layout/AdminLayout'
import ProtectedRoute from './components/layout/ProtectedRoute'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import NotFoundPage from './pages/NotFoundPage'
import PlaceholderPage from './pages/PlaceholderPage'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public */}
          <Route element={<PublicLayout />}>
            <Route path="/" element={<PlaceholderPage title="JaChegai" description="Página inicial — em construção" />} />
            <Route path="/sellers" element={<PlaceholderPage title="Sellers" description="Lista de sellers — em construção" />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </Route>

          {/* Customer */}
          <Route element={<ProtectedRoute roles={['customer']} />}>
            <Route element={<CustomerLayout />}>
              <Route path="/customer/orders" element={<PlaceholderPage title="Meus pedidos" description="Lista de pedidos — em construção" />} />
              <Route path="/customer/cart" element={<PlaceholderPage title="Meu carrinho" description="Carrinho — em construção" />} />
              <Route path="/customer/addresses" element={<PlaceholderPage title="Endereços" description="Endereços — em construção" />} />
              <Route path="/customer/favorites" element={<PlaceholderPage title="Favoritos" description="Favoritos — em construção" />} />
              <Route path="/customer/tickets" element={<PlaceholderPage title="Suporte" description="Tickets — em construção" />} />
              <Route path="/customer/profile" element={<PlaceholderPage title="Meu perfil" description="Perfil — em construção" />} />
            </Route>
          </Route>

          {/* Seller */}
          <Route element={<ProtectedRoute roles={['seller']} />}>
            <Route element={<SellerLayout />}>
              <Route path="/seller/products" element={<PlaceholderPage title="Produtos" description="Gestão de produtos — em construção" />} />
              <Route path="/seller/orders" element={<PlaceholderPage title="Pedidos" description="Pedidos recebidos — em construção" />} />
              <Route path="/seller/inventory" element={<PlaceholderPage title="Estoque" description="Gestão de estoque — em construção" />} />
              <Route path="/seller/categories" element={<PlaceholderPage title="Categorias" description="Categorias — em construção" />} />
              <Route path="/seller/profile" element={<PlaceholderPage title="Perfil da loja" description="Perfil — em construção" />} />
            </Route>
          </Route>

          {/* Courier */}
          <Route element={<ProtectedRoute roles={['courier']} />}>
            <Route element={<CourierLayout />}>
              <Route path="/courier/deliveries" element={<PlaceholderPage title="Entregas" description="Entregas disponíveis — em construção" />} />
              <Route path="/courier/history" element={<PlaceholderPage title="Histórico" description="Histórico de entregas — em construção" />} />
              <Route path="/courier/availability" element={<PlaceholderPage title="Disponibilidade" description="Disponibilidade — em construção" />} />
              <Route path="/courier/stats" element={<PlaceholderPage title="Estatísticas" description="Estatísticas — em construção" />} />
              <Route path="/courier/profile" element={<PlaceholderPage title="Meu perfil" description="Perfil — em construção" />} />
            </Route>
          </Route>

          {/* Admin */}
          <Route element={<ProtectedRoute roles={['admin']} />}>
            <Route element={<AdminLayout />}>
              <Route path="/admin/dashboard" element={<PlaceholderPage title="Dashboard" description="Métricas — em construção" />} />
              <Route path="/admin/users" element={<PlaceholderPage title="Usuários" description="Gestão de usuários — em construção" />} />
              <Route path="/admin/sellers" element={<PlaceholderPage title="Sellers" description="Moderação — em construção" />} />
              <Route path="/admin/couriers" element={<PlaceholderPage title="Couriers" description="Moderação — em construção" />} />
              <Route path="/admin/orders" element={<PlaceholderPage title="Pedidos" description="Oversight — em construção" />} />
              <Route path="/admin/payments" element={<PlaceholderPage title="Pagamentos" description="Pagamentos — em construção" />} />
              <Route path="/admin/tickets" element={<PlaceholderPage title="Tickets" description="Suporte — em construção" />} />
              <Route path="/admin/invoices" element={<PlaceholderPage title="Faturas" description="Faturas — em construção" />} />
              <Route path="/admin/settings" element={<PlaceholderPage title="Configurações" description="Configurações — em construção" />} />
              <Route path="/admin/observability" element={<PlaceholderPage title="Observabilidade" description="Métricas do sistema — em construção" />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App

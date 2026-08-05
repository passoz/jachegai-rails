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
import HomePage from './pages/HomePage'
import SellersPage from './pages/SellersPage'
import SellerDetailPage from './pages/SellerDetailPage'
import ProductDetailPage from './pages/ProductDetailPage'
import NotFoundPage from './pages/NotFoundPage'
import PlaceholderPage from './pages/PlaceholderPage'
import ProfilePage from './pages/customer/ProfilePage'
import AddressesPage from './pages/customer/AddressesPage'
import FavoritesPage from './pages/customer/FavoritesPage'
import CartPage from './pages/customer/CartPage'
import CheckoutPage from './pages/customer/CheckoutPage'
import OrdersPage from './pages/customer/OrdersPage'
import TrackingPage from './pages/customer/TrackingPage'
import TicketsPage from './pages/customer/TicketsPage'
import TicketDetailPage from './pages/customer/TicketDetailPage'
import SellerOnboardingPage from './pages/seller/OnboardingPage'
import SellerProfilePage from './pages/seller/ProfilePage'
import SellerSettingsPage from './pages/seller/SettingsPage'
import SellerCategoriesPage from './pages/seller/CategoriesPage'
import SellerProductsPage from './pages/seller/ProductsPage'
import SellerInventoryPage from './pages/seller/InventoryPage'
import SellerOrdersPage from './pages/seller/OrdersPage'
import SellerOrderDetailPage from './pages/seller/OrderDetailPage'
import CourierOnboardingPage from './pages/courier/OnboardingPage'
import CourierProfilePage from './pages/courier/ProfilePage'
import CourierAvailabilityPage from './pages/courier/AvailabilityPage'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public */}
          <Route element={<PublicLayout />}>
            <Route path="/" element={<HomePage />} />
            <Route path="/sellers" element={<SellersPage />} />
            <Route path="/sellers/:id" element={<SellerDetailPage />} />
            <Route path="/products/:id" element={<ProductDetailPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/about" element={<PlaceholderPage title="Sobre o JaChegai" description="Sobre nós — em construção" />} />
            <Route path="/faq" element={<PlaceholderPage title="FAQ" description="Perguntas frequentes — em construção" />} />
            <Route path="/terms" element={<PlaceholderPage title="Termos de Uso" description="Termos — em construção" />} />
            <Route path="/privacy" element={<PlaceholderPage title="Privacidade" description="Política de privacidade — em construção" />} />
            <Route path="/cookies" element={<PlaceholderPage title="Cookies" description="Política de cookies — em construção" />} />
            <Route path="/lgpd" element={<PlaceholderPage title="LGPD" description="LGPD — em construção" />} />
            <Route path="/contact" element={<PlaceholderPage title="Contato" description="Contato — em construção" />} />
            <Route path="/become-seller" element={<PlaceholderPage title="Seja um seller" description="Parceiro — em construção" />} />
            <Route path="/become-courier" element={<PlaceholderPage title="Seja um courier" description="Parceiro — em construção" />} />
            <Route path="*" element={<NotFoundPage />} />
          </Route>

          {/* Customer */}
          <Route element={<ProtectedRoute roles={['customer']} />}>
            <Route element={<CustomerLayout />}>
              <Route path="/customer/orders" element={<OrdersPage />} />
              <Route path="/customer/orders/:id" element={<TrackingPage />} />
              <Route path="/customer/tracking/:id" element={<TrackingPage />} />
              <Route path="/customer/cart" element={<CartPage />} />
              <Route path="/customer/checkout" element={<CheckoutPage />} />
              <Route path="/customer/addresses" element={<AddressesPage />} />
              <Route path="/customer/favorites" element={<FavoritesPage />} />
              <Route path="/customer/tickets" element={<TicketsPage />} />
              <Route path="/customer/tickets/:id" element={<TicketDetailPage />} />
              <Route path="/customer/profile" element={<ProfilePage />} />
            </Route>
          </Route>

          {/* Seller */}
          <Route element={<ProtectedRoute roles={['seller']} />}>
            <Route element={<SellerLayout />}>
              <Route path="/seller/onboarding" element={<SellerOnboardingPage />} />
              <Route path="/seller/products" element={<SellerProductsPage />} />
              <Route path="/seller/orders" element={<SellerOrdersPage />} />
              <Route path="/seller/orders/:id" element={<SellerOrderDetailPage />} />
              <Route path="/seller/inventory" element={<SellerInventoryPage />} />
              <Route path="/seller/categories" element={<SellerCategoriesPage />} />
              <Route path="/seller/settings" element={<SellerSettingsPage />} />
              <Route path="/seller/profile" element={<SellerProfilePage />} />
            </Route>
          </Route>

          {/* Courier */}
          <Route element={<ProtectedRoute roles={['courier']} />}>
            <Route element={<CourierLayout />}>
              <Route path="/courier/onboarding" element={<CourierOnboardingPage />} />
              <Route path="/courier/deliveries" element={<PlaceholderPage title="Entregas" description="Entregas disponíveis — em construção" />} />
              <Route path="/courier/history" element={<PlaceholderPage title="Histórico" description="Histórico de entregas — em construção" />} />
              <Route path="/courier/availability" element={<CourierAvailabilityPage />} />
              <Route path="/courier/stats" element={<PlaceholderPage title="Estatísticas" description="Estatísticas — em construção" />} />
              <Route path="/courier/profile" element={<CourierProfilePage />} />
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

import { Outlet } from 'react-router-dom'
import Header from './Header'
import Footer from './Footer'

export default function CourierLayout() {
  return (
    <div className="min-h-screen flex flex-col bg-brutal-white">
      <Header />
      <main className="flex-1 max-w-6xl w-full mx-auto px-6 py-8">
        <Outlet />
      </main>
      <Footer />
    </div>
  )
}

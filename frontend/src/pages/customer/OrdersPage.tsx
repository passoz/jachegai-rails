import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import PageTitle from '../../components/ui/PageTitle'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'

export default function OrdersPage() {
  const [orderId, setOrderId] = useState('')
  const navigate = useNavigate()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (orderId.trim()) {
      navigate(`/customer/tracking/${orderId.trim()}`)
    }
  }

  return (
    <div>
      <PageTitle title="Acompanhar pedido" subtitle="Consulte o status e o rastreamento em tempo real" />

      <div className="max-w-xl border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
        <form onSubmit={handleSearch} className="space-y-6">
          <Input
            label="Código do pedido (ID)"
            placeholder="Digite o código do pedido (UUID)"
            value={orderId}
            onChange={(e) => setOrderId(e.target.value)}
            required
          />

          <Button type="submit" variant="primary" className="w-full">
            Ver tracking →
          </Button>
        </form>
      </div>
    </div>
  )
}

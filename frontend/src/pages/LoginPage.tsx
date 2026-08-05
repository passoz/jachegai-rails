import { useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Card from '../components/ui/Card'
import Input from '../components/ui/Input'
import Button from '../components/ui/Button'
import { useAuth } from '../contexts/useAuth'
import { unwrapError } from '../services/api'

export default function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const expired = searchParams.get('expired') === 'true'

  const redirectByRole = (roles: string[]) => {
    if (roles.includes('admin')) return '/admin/dashboard'
    if (roles.includes('seller')) return '/seller/products'
    if (roles.includes('courier')) return '/courier/deliveries'
    return '/customer/orders'
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    try {
      await login(email, password)
      const stored = localStorage.getItem('jachegai_user')
      const user = stored ? (JSON.parse(stored) as { roles: string[] }) : null
      navigate(redirectByRole(user?.roles ?? []))
    } catch (err) {
      const apiError = unwrapError(err)
      setError(apiError.message || 'Email ou senha incorretos.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[70vh] flex items-center justify-center">
      <Card className="w-full max-w-md">
        <h1 className="font-black italic text-3xl text-brutal-black mb-1">Entrar</h1>
        <p className="text-black/60 mb-6">Acesse sua conta JaChegai</p>

        {expired && (
          <div className="mb-5 border-4 border-brutal-black rounded-[1.5rem] bg-brutal-red/20 p-4">
            <p className="font-bold text-brutal-black">Sua sessão expirou. Faça login novamente.</p>
          </div>
        )}

        {error && (
          <div className="mb-5 border-4 border-brutal-black rounded-[1.5rem] bg-brutal-red/20 p-4">
            <p className="font-bold text-brutal-black">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Email"
            name="email"
            type="email"
            placeholder="voce@exemplo.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
          <Input
            label="Senha"
            name="password"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="current-password"
          />
          <Button type="submit" loading={loading} className="w-full">
            Entrar
          </Button>
        </form>

        <p className="mt-6 text-center text-black/60">
          Não tem conta?{' '}
          <Link to="/register" className="font-bold text-brutal-red underline">
            Criar conta
          </Link>
        </p>
      </Card>
    </div>
  )
}

import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Card from '../components/ui/Card'
import Input from '../components/ui/Input'
import Button from '../components/ui/Button'
import { useAuth } from '../contexts/useAuth'
import { unwrapError } from '../services/api'

export default function RegisterPage() {
  const { register } = useAuth()
  const navigate = useNavigate()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setErrors({})
    setFormError(null)

    const next: Record<string, string> = {}
    if (!name.trim()) next.name = 'Informe seu nome completo.'
    if (!/^\S+@\S+\.\S+$/.test(email)) next.email = 'Informe um email válido.'
    if (password.length < 6) next.password = 'A senha deve ter pelo menos 6 caracteres.'
    if (password !== confirm) next.confirm = 'As senhas não coincidem.'
    if (Object.keys(next).length > 0) {
      setErrors(next)
      return
    }

    setLoading(true)
    try {
      await register(name, email, password)
      navigate('/customer/orders')
    } catch (err) {
      const apiError = unwrapError(err)
      if (apiError.code === 'validation_failed' && apiError.context) {
        // Map backend field errors to inputs
        const ctx = apiError.context as Record<string, unknown>
        const fieldErrors: Record<string, string> = {}
        Object.entries(ctx).forEach(([key, value]) => {
          fieldErrors[key] = String(value)
        })
        setErrors(fieldErrors)
      } else {
        setFormError(apiError.message)
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[70vh] flex items-center justify-center">
      <Card className="w-full max-w-md">
        <h1 className="font-black italic text-3xl text-brutal-black mb-1">Criar conta</h1>
        <p className="text-black/60 mb-6">Comece a comprar no JaChegai</p>

        {formError && (
          <div className="mb-5 border-4 border-brutal-black rounded-[1.5rem] bg-brutal-red/20 p-4">
            <p className="font-bold text-brutal-black">{formError}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Nome completo"
            name="name"
            placeholder="Maria Silva"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
            required
            autoComplete="name"
          />
          <Input
            label="Email"
            name="email"
            type="email"
            placeholder="voce@exemplo.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={errors.email}
            required
            autoComplete="email"
          />
          <Input
            label="Senha"
            name="password"
            type="password"
            placeholder="Mínimo 6 caracteres"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={errors.password}
            required
            autoComplete="new-password"
          />
          <Input
            label="Confirmar senha"
            name="confirm"
            type="password"
            placeholder="Repita a senha"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            error={errors.confirm}
            required
            autoComplete="new-password"
          />
          <Button type="submit" loading={loading} className="w-full">
            Criar conta
          </Button>
        </form>

        <p className="mt-6 text-center text-black/60">
          Já tem conta?{' '}
          <Link to="/login" className="font-bold text-brutal-red underline">
            Entrar
          </Link>
        </p>
      </Card>
    </div>
  )
}

import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../../contexts/useAuth'
import LoadingSpinner from '../ui/LoadingSpinner'

interface ProtectedRouteProps {
  roles: string[]
}

export default function ProtectedRoute({ roles }: ProtectedRouteProps) {
  const { isAuthenticated, loading, hasRole } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-brutal-white">
        <LoadingSpinner />
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  if (!roles.some((r) => hasRole(r))) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-brutal-white p-6">
        <div className="max-w-md w-full border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-brutal-red/20 p-10 text-center">
          <div className="text-5xl mb-3" aria-hidden="true">🚫</div>
          <h1 className="font-black italic text-3xl text-brutal-black mb-2">Acesso negado</h1>
          <p className="text-black/70">Você não tem permissão para acessar esta área.</p>
        </div>
      </div>
    )
  }

  return <Outlet />
}

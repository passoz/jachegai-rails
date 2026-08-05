import { useCallback, useEffect, useState, type ReactNode } from 'react'
import * as authService from '../services/auth'
import { tokenStore } from '../services/api'
import type { User } from '../services/auth'
import { AuthContext } from './authContext'

const USER_KEY = 'jachegai_user'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(() => {
    try {
      const raw = localStorage.getItem(USER_KEY)
      return raw ? (JSON.parse(raw) as User) : null
    } catch {
      return null
    }
  })
  const [token, setToken] = useState<string | null>(() => tokenStore.get())
  const [loading, setLoading] = useState<boolean>(true)

  useEffect(() => {
    let cancelled = false
    const validate = async () => {
      const storedToken = tokenStore.get()
      if (!storedToken) {
        setLoading(false)
        return
      }
      try {
        const me = await authService.getMe()
        if (!cancelled) {
          setUser(me)
          localStorage.setItem(USER_KEY, JSON.stringify(me))
        }
      } catch {
        if (!cancelled) {
          setUser(null)
          setToken(null)
          tokenStore.clear()
          localStorage.removeItem(USER_KEY)
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    validate()
    return () => {
      cancelled = true
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const data = await authService.login({ email, password })
    setToken(data.token)
    setUser(data.user)
    tokenStore.set(data.token)
    localStorage.setItem(USER_KEY, JSON.stringify(data.user))
  }, [])

  const register = useCallback(async (name: string, email: string, password: string) => {
    const data = await authService.register({ name, email, password })
    setToken(data.token)
    setUser(data.user)
    tokenStore.set(data.token)
    localStorage.setItem(USER_KEY, JSON.stringify(data.user))
  }, [])

  const logout = useCallback(async () => {
    await authService.logout()
    setUser(null)
    setToken(null)
    tokenStore.clear()
    localStorage.removeItem(USER_KEY)
  }, [])

  const hasRole = useCallback(
    (role: string) => Boolean(user?.roles.includes(role)),
    [user],
  )

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        loading,
        isAuthenticated: Boolean(user && token),
        login,
        register,
        logout,
        hasRole,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

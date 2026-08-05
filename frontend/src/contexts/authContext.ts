import { createContext } from 'react'
import type { User } from '../services/auth'

export interface AuthContextValue {
  user: User | null
  token: string | null
  loading: boolean
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  register: (name: string, email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  hasRole: (role: string) => boolean
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined)

import api, { unwrap } from './api'

export interface User {
  id: string
  email: string
  name: string
  roles: string[]
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  name: string
  email: string
  password: string
}

interface AuthData {
  token: string
  user: User
}

export async function login(payload: LoginRequest): Promise<AuthData> {
  const response = await api.post('/api/v1/auth/login', payload)
  return unwrap<AuthData>(response)
}

export async function register(payload: RegisterRequest): Promise<AuthData> {
  const response = await api.post('/api/v1/auth/register', payload)
  return unwrap<AuthData>(response)
}

export async function logout(): Promise<void> {
  try {
    await api.post('/api/v1/auth/logout')
  } catch {
    // ignore network errors on logout
  }
}

export async function getMe(): Promise<User> {
  const response = await api.get('/api/v1/auth/me')
  return unwrap<User>(response)
}

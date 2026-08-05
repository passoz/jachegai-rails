import axios, { AxiosError } from 'axios'

export interface ApiResponse<T> {
  ok: boolean
  data: T
  meta?: Record<string, unknown>
}

export interface ApiError {
  code: string
  message: string
  context?: Record<string, unknown>
}

const TOKEN_KEY = 'jachegai_token'

export const tokenStore = {
  get: () => localStorage.getItem(TOKEN_KEY),
  set: (token: string) => localStorage.setItem(TOKEN_KEY, token),
  clear: () => localStorage.removeItem(TOKEN_KEY),
}

const api = axios.create({
  baseURL: '',
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = tokenStore.get()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      tokenStore.clear()
      localStorage.removeItem('jachegai_user')
      if (window.location.pathname !== '/login') {
        window.location.href = '/login?expired=true'
      }
    }
    return Promise.reject(error)
  },
)

export function unwrap<T>(response: { data: ApiResponse<T> }): T {
  return response.data.data
}

export function unwrapError(error: unknown): ApiError {
  if (axios.isAxiosError(error)) {
    const body = error.response?.data as { error?: ApiError } | undefined
    if (body?.error) return body.error
    return {
      code: 'network_error',
      message: 'Falha de conexão com o servidor.',
    }
  }
  return {
    code: 'unknown',
    message: 'Erro inesperado.',
  }
}

export default api

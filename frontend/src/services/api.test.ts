import { describe, it, expect, beforeEach } from 'vitest'
import api, { tokenStore, unwrap, unwrapError } from './api'
import type { InternalAxiosRequestConfig } from 'axios'

describe('tokenStore', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('stores and retrieves token', () => {
    tokenStore.set('abc123')
    expect(tokenStore.get()).toBe('abc123')
  })

  it('clears token', () => {
    tokenStore.set('abc123')
    tokenStore.clear()
    expect(tokenStore.get()).toBeNull()
  })
})

describe('api request interceptor', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('adds Authorization header when token exists', () => {
    tokenStore.set('mytoken')
    const config: InternalAxiosRequestConfig = {
      headers: {},
    } as InternalAxiosRequestConfig
    // Trigger interceptor by calling it directly via the axios instance
    const handler = (api.interceptors.request as unknown as {
      handlers: Array<{ fulfilled: (c: InternalAxiosRequestConfig) => InternalAxiosRequestConfig }>
    }).handlers[0].fulfilled
    const result = handler(config)
    expect(result.headers.Authorization).toBe('Bearer mytoken')
  })

  it('does not add Authorization header when no token', () => {
    const config: InternalAxiosRequestConfig = {
      headers: {},
    } as InternalAxiosRequestConfig
    const handler = (api.interceptors.request as unknown as {
      handlers: Array<{ fulfilled: (c: InternalAxiosRequestConfig) => InternalAxiosRequestConfig }>
    }).handlers[0].fulfilled
    const result = handler(config)
    expect(result.headers.Authorization).toBeUndefined()
  })
})

describe('unwrap', () => {
  it('returns data from envelope', () => {
    const response = { data: { ok: true, data: { id: '1' }, meta: {} } }
    expect(unwrap(response)).toEqual({ id: '1' })
  })
})

describe('unwrapError', () => {
  it('extracts api error body', () => {
    const error = {
      isAxiosError: true,
      response: { data: { error: { code: 'unauthorized', message: 'não autorizado' } } },
    }
    expect(unwrapError(error)).toEqual({ code: 'unauthorized', message: 'não autorizado' })
  })

  it('returns network error when no response', () => {
    const error = { isAxiosError: true }
    const result = unwrapError(error)
    expect(result.code).toBe('network_error')
  })

  it('returns unknown error for non-axios', () => {
    const result = unwrapError(new Error('boom'))
    expect(result.code).toBe('unknown')
  })
})

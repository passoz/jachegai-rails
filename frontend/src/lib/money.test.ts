import { describe, it, expect } from 'vitest'
import { formatMoney } from './money'

describe('formatMoney', () => {
  it('formats 1250 BRL as R$ 12,50', () => {
    expect(formatMoney(1250, 'BRL')).toBe('R$\u00a012,50')
  })

  it('formats 0 as R$ 0,00', () => {
    expect(formatMoney(0, 'BRL')).toBe('R$\u00a00,00')
  })

  it('formats large amounts', () => {
    expect(formatMoney(123456, 'BRL')).toBe('R$\u00a01.234,56')
  })

  it('formats 1 cent', () => {
    expect(formatMoney(1, 'BRL')).toBe('R$\u00a00,01')
  })
})

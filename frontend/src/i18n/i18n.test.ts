import { describe, it, expect } from 'vitest'
import { i18n } from './pt-BR'

describe('i18n dictionary', () => {
  it('contains status translations for all backend states (UX-005)', () => {
    expect(i18n.status.pending).toBe('Pendente')
    expect(i18n.status.accepted).toBe('Aceito')
    expect(i18n.status.rejected).toBe('Rejeitado')
    expect(i18n.status.preparing).toBe('Em preparo')
    expect(i18n.status.ready).toBe('Pronto')
    expect(i18n.status.assigned).toBe('Em entrega')
    expect(i18n.status.picked_up).toBe('Coletado')
    expect(i18n.status.delivered).toBe('Entregue')
    expect(i18n.status.cancelled).toBe('Cancelado')
    expect(i18n.status.pending_review).toBe('Aguardando análise')
    expect(i18n.status.approved).toBe('Aprovado')
    expect(i18n.status.suspended).toBe('Suspenso')
  })
})

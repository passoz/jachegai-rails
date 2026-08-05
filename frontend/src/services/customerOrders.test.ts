import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
  unwrap: (response: { data: { data: unknown } }) => response.data.data,
}))

import api from './api'
import {
  cancelCustomerOrder,
  getCustomerOrderTracking,
  listCustomerTickets,
  getCustomerTicket,
  createCustomerTicket,
  addCustomerTicketMessage,
} from './customerOrders'

const mockGet = api.get as ReturnType<typeof vi.fn>
const mockPost = api.post as ReturnType<typeof vi.fn>

const trackingData = {
  order_id: 'o1',
  order_state: 'assigned',
  courier_location: { latitude: -23.55, longitude: -46.63, recorded_at: '2026-08-05T18:00:00Z' },
  history: [{ state: 'assigned', at: '2026-08-05T18:00:00Z', actor: 'courier' }],
}

const ticketData = {
  id: 't1',
  subject: 'Atraso na entrega',
  status: 'open',
  created_at: '2026-08-05T10:00:00Z',
  messages: [{ id: 'm1', body: 'Meu pedido atrasou', sender: 'customer', created_at: '2026-08-05T10:00:00Z' }],
}

describe('customerOrders service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('cancelCustomerOrder POSTs /api/v1/customer/orders/:id/cancel', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: { id: 'o1', status: 'cancelled' } } })
    await cancelCustomerOrder('o1', 'Mudei de ideia')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/orders/o1/cancel', { reason: 'Mudei de ideia' })
  })

  it('getCustomerOrderTracking GETs /api/v1/customer/orders/:id/tracking', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: trackingData } })
    const res = await getCustomerOrderTracking('o1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/orders/o1/tracking')
    expect(res.order_state).toBe('assigned')
  })

  it('listCustomerTickets GETs /api/v1/customer/tickets', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: [ticketData] } })
    const res = await listCustomerTickets()
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/tickets')
    expect(res[0].subject).toBe('Atraso na entrega')
  })

  it('getCustomerTicket GETs /api/v1/customer/tickets/:id', async () => {
    mockGet.mockResolvedValue({ data: { ok: true, data: ticketData } })
    const res = await getCustomerTicket('t1')
    expect(mockGet).toHaveBeenCalledWith('/api/v1/customer/tickets/t1')
    expect(res.id).toBe('t1')
  })

  it('createCustomerTicket POSTs /api/v1/customer/tickets', async () => {
    mockPost.mockResolvedValue({ data: { ok: true, data: ticketData } })
    await createCustomerTicket('Preciso de ajuda', 'Mensagem inicial', 'o1')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/tickets', {
      subject: 'Preciso de ajuda',
      message: 'Mensagem inicial',
      order_id: 'o1',
    })
  })

  it('addCustomerTicketMessage POSTs /api/v1/customer/tickets/:id/messages', async () => {
    const newMsg = { id: 'm2', body: 'Obrigado', sender: 'customer' }
    mockPost.mockResolvedValue({ data: { ok: true, data: newMsg } })
    await addCustomerTicketMessage('t1', 'Obrigado')
    expect(mockPost).toHaveBeenCalledWith('/api/v1/customer/tickets/t1/messages', { body: 'Obrigado' })
  })
})

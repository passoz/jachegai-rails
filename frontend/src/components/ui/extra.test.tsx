import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import EmptyState from './EmptyState'
import ErrorState from './ErrorState'
import LoadingSpinner from './LoadingSpinner'
import PageTitle from './PageTitle'
import Card from './Card'
import Button from './Button'

describe('EmptyState', () => {
  it('renders title and description', () => {
    render(<EmptyState title="Sem pedidos" description="Você ainda não fez pedidos." />)
    expect(screen.getByText('Sem pedidos')).toBeInTheDocument()
    expect(screen.getByText('Você ainda não fez pedidos.')).toBeInTheDocument()
  })

  it('renders action element', () => {
    render(
      <EmptyState
        title="Vazio"
        action={
          <Button>
            Explorar sellers
          </Button>
        }
      />,
    )
    expect(screen.getByRole('button', { name: 'Explorar sellers' })).toBeInTheDocument()
  })
})

describe('ErrorState', () => {
  it('renders default title and message', () => {
    render(<ErrorState />)
    expect(screen.getByText('Ops, algo deu errado.')).toBeInTheDocument()
  })

  it('renders custom message', () => {
    render(<ErrorState message="Falha ao carregar" />)
    expect(screen.getByText('Falha ao carregar')).toBeInTheDocument()
  })

  it('calls onRetry when button clicked', async () => {
    const onRetry = vi.fn()
    render(<ErrorState onRetry={onRetry} />)
    await userEvent.click(screen.getByRole('button', { name: 'Tentar novamente' }))
    expect(onRetry).toHaveBeenCalledTimes(1)
  })
})

describe('LoadingSpinner', () => {
  it('renders default label', () => {
    render(<LoadingSpinner />)
    expect(screen.getByText('Carregando...')).toBeInTheDocument()
  })

  it('renders custom label', () => {
    render(<LoadingSpinner label="Buscando sellers" />)
    expect(screen.getByText('Buscando sellers')).toBeInTheDocument()
  })
})

describe('PageTitle', () => {
  it('renders title', () => {
    render(<PageTitle title="Meus pedidos" />)
    expect(screen.getByRole('heading', { level: 1, name: 'Meus pedidos' })).toBeInTheDocument()
  })

  it('renders subtitle', () => {
    render(<PageTitle title="Meus pedidos" subtitle="Acompanhe suas compras" />)
    expect(screen.getByText('Acompanhe suas compras')).toBeInTheDocument()
  })

  it('uses italic bold classes', () => {
    render(<PageTitle title="Meus pedidos" />)
    expect(screen.getByRole('heading', { level: 1 })).toHaveClass('font-black', 'italic')
  })
})

describe('Card', () => {
  it('renders children', () => {
    render(<Card>Conteúdo do card</Card>)
    expect(screen.getByText('Conteúdo do card')).toBeInTheDocument()
  })

  it('applies brutalist classes', () => {
    const { container } = render(<Card>Conteúdo</Card>)
    expect(container.firstElementChild?.className).toContain('border-4')
    expect(container.firstElementChild?.className).toContain('rounded-[1.5rem]')
  })
})

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Button from './Button'

describe('Button', () => {
  it('renders children text', () => {
    render(<Button>Entrar</Button>)
    expect(screen.getByRole('button', { name: 'Entrar' })).toBeInTheDocument()
  })

  it('renders default type="button"', () => {
    render(<Button>OK</Button>)
    expect(screen.getByRole('button')).toHaveAttribute('type', 'button')
  })

  it('applies brutalist border classes', () => {
    render(<Button>OK</Button>)
    const btn = screen.getByRole('button')
    expect(btn.className).toContain('border-4')
    expect(btn.className).toContain('border-brutal-black')
    expect(btn.className).toContain('rounded-[1.5rem]')
  })

  it('applies variant danger classes', () => {
    render(<Button variant="danger">Excluir</Button>)
    expect(screen.getByRole('button').className).toContain('bg-brutal-red')
  })

  it('applies variant outline classes', () => {
    render(<Button variant="outline">Cancelar</Button>)
    expect(screen.getByRole('button').className).toContain('bg-white')
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>OK</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })

  it('shows loading indicator and disables when loading', () => {
    render(<Button loading>Salvar</Button>)
    const btn = screen.getByRole('button')
    expect(btn).toBeDisabled()
    expect(btn).toHaveTextContent('...')
  })

  it('fires onClick when clicked', async () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick}>Clicar</Button>)
    await userEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('does not fire onClick when disabled', async () => {
    const handleClick = vi.fn()
    render(
      <Button onClick={handleClick} disabled>
        Clicar
      </Button>,
    )
    await userEvent.click(screen.getByRole('button'))
    expect(handleClick).not.toHaveBeenCalled()
  })
})

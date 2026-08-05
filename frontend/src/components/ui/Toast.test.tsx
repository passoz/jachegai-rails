import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Toast from './Toast'

describe('Toast component', () => {
  it('renders success toast with message', () => {
    render(<Toast open type="success" message="Operação realizada com sucesso!" onClose={() => {}} />)
    expect(screen.getByText('Operação realizada com sucesso!')).toBeInTheDocument()
  })

  it('renders error toast with message', () => {
    render(<Toast open type="error" message="Erro ao salvar dados" onClose={() => {}} />)
    expect(screen.getByText('Erro ao salvar dados')).toBeInTheDocument()
  })

  it('calls onClose when clicking close button', async () => {
    const handleClose = vi.fn()
    const user = userEvent.setup()
    render(<Toast open type="success" message="Sucesso" onClose={handleClose} />)

    await user.click(screen.getByRole('button', { name: /fechar/i }))
    expect(handleClose).toHaveBeenCalled()
  })
})

import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Modal from './Modal'

describe('Modal', () => {
  it('renders nothing when closed', () => {
    const { container } = render(
      <Modal open={false} onClose={() => {}} title="Título">
        <p>Conteúdo</p>
      </Modal>,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('renders title and content when open', () => {
    render(
      <Modal open onClose={() => {}} title="Editar endereço">
        <p>Formulário aqui</p>
      </Modal>,
    )
    expect(screen.getByText('Editar endereço')).toBeInTheDocument()
    expect(screen.getByText('Formulário aqui')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', async () => {
    const handleClose = vi.fn()
    render(
      <Modal open onClose={handleClose} title="Título">
        <p>Conteúdo</p>
      </Modal>,
    )
    await userEvent.click(screen.getByLabelText('Fechar'))
    expect(handleClose).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when overlay is clicked', async () => {
    const handleClose = vi.fn()
    const { container } = render(
      <Modal open onClose={handleClose} title="Título">
        <p>Conteúdo</p>
      </Modal>,
    )
    fireEvent.click(container.firstElementChild as HTMLElement)
    expect(handleClose).toHaveBeenCalledTimes(1)
  })

  it('does not close when clicking inside content', async () => {
    const handleClose = vi.fn()
    render(
      <Modal open onClose={handleClose} title="Título">
        <p>Conteúdo</p>
      </Modal>,
    )
    await userEvent.click(screen.getByText('Conteúdo'))
    expect(handleClose).not.toHaveBeenCalled()
  })

  it('closes on Escape key', async () => {
    const handleClose = vi.fn()
    render(
      <Modal open onClose={handleClose} title="Título">
        <p>Conteúdo</p>
      </Modal>,
    )
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(handleClose).toHaveBeenCalledTimes(1)
  })

  it('has role dialog and aria-modal', () => {
    render(
      <Modal open onClose={() => {}} title="Título">
        <p>Conteúdo</p>
      </Modal>,
    )
    const dialog = screen.getByRole('dialog')
    expect(dialog).toHaveAttribute('aria-modal', 'true')
  })
})

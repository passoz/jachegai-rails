import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfirmDialog from './ConfirmDialog'

describe('ConfirmDialog', () => {
  it('renders message and confirm/cancel buttons', () => {
    render(
      <ConfirmDialog
        open
        title="Excluir endereço"
        message="Tem certeza que deseja excluir?"
        onConfirm={() => {}}
        onCancel={() => {}}
      />,
    )
    expect(screen.getByText('Excluir endereço')).toBeInTheDocument()
    expect(screen.getByText('Tem certeza que deseja excluir?')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Confirmar' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Cancelar' })).toBeInTheDocument()
  })

  it('renders custom confirm label', () => {
    render(
      <ConfirmDialog
        open
        title="Título"
        message="Mensagem"
        confirmLabel="Sim, cancelar"
        onConfirm={() => {}}
        onCancel={() => {}}
      />,
    )
    expect(screen.getByRole('button', { name: 'Sim, cancelar' })).toBeInTheDocument()
  })

  it('calls onConfirm when confirm button is clicked', async () => {
    const handleConfirm = vi.fn()
    render(
      <ConfirmDialog
        open
        title="Título"
        message="Mensagem"
        onConfirm={handleConfirm}
        onCancel={() => {}}
      />,
    )
    await userEvent.click(screen.getByRole('button', { name: 'Confirmar' }))
    expect(handleConfirm).toHaveBeenCalledTimes(1)
  })

  it('calls onCancel when cancel button is clicked', async () => {
    const handleCancel = vi.fn()
    render(
      <ConfirmDialog
        open
        title="Título"
        message="Mensagem"
        onConfirm={() => {}}
        onCancel={handleCancel}
      />,
    )
    await userEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    expect(handleCancel).toHaveBeenCalledTimes(1)
  })

  it('disables buttons while loading', () => {
    render(
      <ConfirmDialog
        open
        title="Título"
        message="Mensagem"
        onConfirm={() => {}}
        onCancel={() => {}}
        loading
      />,
    )
    // During loading the confirm button shows the loading indicator
    const buttons = screen.getAllByRole('button')
    const dialogButtons = buttons.filter((b) => b.getAttribute('aria-label') !== 'Fechar')
    expect(dialogButtons.length).toBe(2)
    dialogButtons.forEach((btn) => expect(btn).toBeDisabled())
  })
})

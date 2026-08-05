import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import Input from './Input'

describe('Input', () => {
  it('renders label and input', () => {
    render(<Input label="Email" name="email" />)
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByRole('textbox')).toHaveAttribute('name', 'email')
  })

  it('applies brutalist classes', () => {
    render(<Input name="email" />)
    expect(screen.getByRole('textbox').className).toContain('border-4')
    expect(screen.getByRole('textbox').className).toContain('border-brutal-black')
  })

  it('shows error message when error prop is set', () => {
    render(<Input label="Email" name="email" error="Email inválido" />)
    expect(screen.getByText('Email inválido')).toBeInTheDocument()
  })

  it('applies error border class when error is set', () => {
    render(<Input name="email" error="erro" />)
    expect(screen.getByRole('textbox').className).toContain('border-brutal-red')
  })

  it('passes value and onChange to input', () => {
    const handleChange = vi.fn()
    render(<Input name="email" value="a@b.com" onChange={handleChange} />)
    const input = screen.getByRole('textbox')
    expect(input).toHaveValue('a@b.com')
    fireEvent.change(input, { target: { value: 'x@y.com' } })
    expect(handleChange).toHaveBeenCalled()
  })

  it('renders password type input', () => {
    render(<Input label="Senha" name="password" type="password" />)
    expect(screen.getByLabelText('Senha')).toHaveAttribute('type', 'password')
  })
})

import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import Select from './Select'

const options = [
  { value: 'moto', label: 'Moto' },
  { value: 'bicicleta', label: 'Bicicleta' },
  { value: 'carro', label: 'Carro' },
]

describe('Select', () => {
  it('renders label and options', () => {
    render(<Select label="Veículo" name="vehicle" options={options} />)
    expect(screen.getByLabelText('Veículo')).toBeInTheDocument()
    options.forEach((opt) => {
      expect(screen.getByRole('option', { name: opt.label })).toBeInTheDocument()
    })
  })

  it('renders placeholder option', () => {
    render(<Select name="vehicle" options={options} placeholder="Selecione..." />)
    expect(screen.getByRole('option', { name: 'Selecione...' })).toBeInTheDocument()
  })

  it('fires onChange with selected value', () => {
    const handleChange = vi.fn()
    render(<Select name="vehicle" options={options} onChange={handleChange} />)
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'carro' } })
    expect(handleChange).toHaveBeenCalledWith('carro')
  })

  it('shows error message', () => {
    render(<Select name="vehicle" options={options} error="Campo obrigatório" />)
    expect(screen.getByText('Campo obrigatório')).toBeInTheDocument()
  })

  it('is disabled when disabled prop is true', () => {
    render(<Select name="vehicle" options={options} disabled />)
    expect(screen.getByRole('combobox')).toBeDisabled()
  })
})

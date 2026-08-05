export function formatMoney(cents: number, currency = 'BRL'): string {
  const value = cents / 100
  const formatted = new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(value)
  return formatted
}

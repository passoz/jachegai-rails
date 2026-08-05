import type { ReactNode } from 'react'

interface Column<T> {
  key: string
  header: string
  render?: (row: T) => ReactNode
}

interface TableProps<T> {
  columns: Column<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  emptyMessage?: string
}

export default function Table<T>({ columns, data, onRowClick, emptyMessage = 'Nenhum registro encontrado.' }: TableProps<T>) {
  if (data.length === 0) {
    return (
      <div className="border-4 border-brutal-black rounded-[1.5rem] bg-brutal-gray p-10 text-center">
        <p className="font-black italic text-xl text-black/60">{emptyMessage}</p>
      </div>
    )
  }

  return (
    <div className="border-4 border-brutal-black rounded-[1.5rem] overflow-hidden bg-white">
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-brutal-black text-white">
              {columns.map((col) => (
                <th key={col.key} className="px-4 py-3 font-black uppercase tracking-wider text-sm">
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr
                key={i}
                onClick={() => onRowClick?.(row)}
                className={[
                  'border-t-2 border-brutal-black',
                  i % 2 === 0 ? 'bg-white' : 'bg-brutal-gray',
                  onRowClick ? 'cursor-pointer hover:bg-red-50 transition-colors' : '',
                ].join(' ')}
              >
                {columns.map((col) => (
                  <td key={col.key} className="px-4 py-3">
                    {col.render ? col.render(row) : String((row as Record<string, unknown>)[col.key] ?? '')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

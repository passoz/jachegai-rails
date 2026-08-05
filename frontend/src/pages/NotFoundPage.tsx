import { Link } from 'react-router-dom'

export default function NotFoundPage() {
  return (
    <div className="min-h-[70vh] flex items-center justify-center">
      <div className="max-w-md w-full text-center">
        <div className="text-7xl font-black italic text-brutal-black mb-4">404</div>
        <h1 className="font-black italic text-3xl text-brutal-black mb-3">Página não encontrada</h1>
        <p className="text-black/60 mb-6">O endereço que você tentou acessar não existe ou foi movido.</p>
        <Link
          to="/"
          className="inline-block px-6 py-3 border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-brutal-black text-white font-black italic hover:bg-brutal-red hover:text-black transition-all"
        >
          Voltar ao início
        </Link>
      </div>
    </div>
  )
}

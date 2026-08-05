import { Link } from 'react-router-dom'
import PageTitle from '../components/ui/PageTitle'

interface PlaceholderPageProps {
  title: string
  description?: string
}

export default function PlaceholderPage({ title, description }: PlaceholderPageProps) {
  return (
    <div>
      <PageTitle title={title} subtitle={description} />
      <div className="border-4 border-brutal-black rounded-[1.5rem] bg-brutal-gray p-10 text-center">
        <div className="text-5xl mb-3" aria-hidden="true">🚧</div>
        <h3 className="font-black italic text-2xl text-brutal-black mb-2">Em construção</h3>
        <p className="text-black/60 mb-5">Esta página será implementada em uma próxima etapa.</p>
        <Link to="/" className="inline-block px-6 py-3 border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-brutal-black text-white font-black italic hover:bg-brutal-red hover:text-black transition-all">
          Voltar ao início
        </Link>
      </div>
    </div>
  )
}

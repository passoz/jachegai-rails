import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listSellers } from '../services/public'
import type { PublicSeller } from '../types/public'
import SellerCard from '../components/public/SellerCard'
import LoadingSpinner from '../components/ui/LoadingSpinner'
import ErrorState from '../components/ui/ErrorState'
import EmptyState from '../components/ui/EmptyState'

export default function HomePage() {
  const [sellers, setSellers] = useState<PublicSeller[] | null>(null)
  const [error, setError] = useState(false)

  const load = () => {
    setError(false)
    setSellers(null)
    listSellers({ limit: 6 })
      .then((result) => setSellers(result.sellers))
      .catch(() => setError(true))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div>
      {/* Hero */}
      <section className="border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-brutal-black text-white p-10 md:p-14 mb-12">
        <p className="inline-block border-2 border-brutal-red text-brutal-red font-black uppercase text-xs tracking-widest px-3 py-1 rounded-full mb-6">
          Delivery local
        </p>
        <h1 className="font-black italic text-5xl md:text-6xl mb-4">
          Seu delivery. <span className="text-brutal-red">Já chegou.</span>
        </h1>
        <p className="text-white/70 text-xl mb-8 max-w-xl">
          Descubra sellers locais, escolha seus produtos e receba em casa. Rápido, simples e brutal.
        </p>
        <div className="flex flex-wrap gap-4">
          <Link
            to="/sellers"
            className="px-6 py-3 border-4 border-brutal-red rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(255,107,107,1)] bg-brutal-red text-brutal-black font-black italic hover:bg-white hover:border-white hover:shadow-white transition-all"
          >
            Explorar sellers
          </Link>
          <Link
            to="/register"
            className="px-6 py-3 border-4 border-white rounded-[1.5rem] text-white font-black italic hover:bg-white hover:text-brutal-black transition-all"
          >
            Criar conta
          </Link>
        </div>
      </section>

      {/* Como funciona */}
      <section className="mb-12">
        <h2 className="font-black italic text-3xl text-brutal-black mb-6">Como funciona</h2>
        <div className="grid md:grid-cols-3 gap-6">
          {[
            {
              step: '01',
              title: 'Explore',
              text: 'Navegue pelos sellers aprovados da sua região e encontre o que você procura.',
            },
            {
              step: '02',
              title: 'Peça',
              text: 'Adicione produtos ao carrinho e finalize o pedido em poucos cliques.',
            },
            {
              step: '03',
              title: 'Receba',
              text: 'Acompanhe a entrega em tempo real até o produto chegar. Já chegou!',
            },
          ].map((item) => (
            <div
              key={item.step}
              className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-6 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]"
            >
              <p className="font-black italic text-5xl text-brutal-red">{item.step}</p>
              <h3 className="font-black italic text-2xl mt-2 text-brutal-black">{item.title}</h3>
              <p className="text-black/60 mt-2">{item.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Sellers em destaque */}
      <section className="mb-12">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-black italic text-3xl text-brutal-black">Sellers em destaque</h2>
          <Link to="/sellers" className="font-black italic text-brutal-red hover:underline">
            Ver todos →
          </Link>
        </div>
        {error && (
          <ErrorState
            title="Não foi possível carregar os sellers"
            message="Verifique sua conexão e tente novamente."
            onRetry={load}
          />
        )}
        {!error && sellers === null && <LoadingSpinner label="Carregando sellers..." />}
        {!error && sellers !== null && sellers.length === 0 && (
          <EmptyState title="Nenhum seller disponível" description="Volte em breve." />
        )}
        {!error && sellers !== null && sellers.length > 0 && (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {sellers.map((seller) => (
              <SellerCard key={seller.id} seller={seller} />
            ))}
          </div>
        )}
      </section>

      {/* CTA final */}
      <section className="border-4 border-brutal-black rounded-[1.5rem] bg-brutal-red p-10 text-center shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] mb-8">
        <h2 className="font-black italic text-3xl md:text-4xl text-brutal-black mb-3">
          Quer vender no JaChegai?
        </h2>
        <p className="text-brutal-black/70 text-lg mb-6 max-w-xl mx-auto">
          Crie sua conta e abra sua loja hoje mesmo. Sem mensalidade, sem burocracia.
        </p>
        <Link
          to="/register"
          className="inline-block px-6 py-3 border-4 border-brutal-black rounded-[1.5rem] bg-brutal-black text-white font-black italic hover:bg-white hover:text-brutal-black transition-all"
        >
          Começar agora
        </Link>
      </section>

      {/* Seja parceiro / Seja entregador */}
      <section className="grid md:grid-cols-2 gap-6">
        <Link
          to="/become-seller"
          className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5 transition-all"
        >
          <p className="text-4xl" aria-hidden="true">🏪</p>
          <h3 className="font-black italic text-2xl text-brutal-black mt-3">Seja um seller</h3>
          <p className="text-black/60 mt-2">
            Abra sua loja e alcance milhares de clientes. Controle seu catálogo, estoque e pedidos.
          </p>
          <p className="font-black italic text-brutal-red mt-4">Quero vender →</p>
        </Link>
        <Link
          to="/become-courier"
          className="border-4 border-brutal-black rounded-[1.5rem] bg-white p-8 shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5 transition-all"
        >
          <p className="text-4xl" aria-hidden="true">🛵</p>
          <h3 className="font-black italic text-2xl text-brutal-black mt-3">Seja um courier</h3>
          <p className="text-black/60 mt-2">
            Ganhe dinheiro fazendo entregas no seu ritmo. Trabalhe quando quiser.
          </p>
          <p className="font-black italic text-brutal-red mt-4">Quero entregar →</p>
        </Link>
      </section>
    </div>
  )
}

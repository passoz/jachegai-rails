import { Link } from 'react-router-dom'

const footerColumns = [
  {
    title: 'JaChegai',
    links: [
      { label: 'Sobre nós', to: '/about' },
      { label: 'Como funciona', to: '/' },
      { label: 'Seja um parceiro', to: '/become-seller' },
      { label: 'Seja um entregador', to: '/become-courier' },
    ],
  },
  {
    title: 'Para você',
    links: [
      { label: 'Descubra sellers', to: '/sellers' },
      { label: 'Meus pedidos', to: '/customer/orders' },
      { label: 'Meu carrinho', to: '/customer/cart' },
      { label: 'Suporte', to: '/customer/tickets' },
    ],
  },
  {
    title: 'Suporte',
    links: [
      { label: 'FAQ', to: '/faq' },
      { label: 'Termos de uso', to: '/terms' },
      { label: 'Privacidade', to: '/privacy' },
      { label: 'Contato', to: '/contact' },
    ],
  },
  {
    title: 'Siga-nos',
    links: [
      { label: 'Instagram', to: '#' },
      { label: 'Facebook', to: '#' },
      { label: 'X (Twitter)', to: '#' },
      { label: 'LinkedIn', to: '#' },
    ],
  },
]

export default function Footer() {
  return (
    <footer className="border-t-4 border-brutal-red bg-brutal-black text-white mt-16">
      <div className="max-w-6xl mx-auto px-6 py-12 grid grid-cols-2 md:grid-cols-4 gap-8">
        <div>
          <h4 className="font-black italic text-2xl mb-3">
            <span className="text-brutal-red">Ja</span>Chegai
          </h4>
          <p className="text-white/60 text-sm">Seu delivery. Já chegou.</p>
        </div>

        {footerColumns.slice(1).map((col) => (
          <div key={col.title}>
            <h5 className="font-black uppercase text-sm tracking-wider mb-3 text-brutal-red">
              {col.title}
            </h5>
            <ul className="space-y-2">
              {col.links.map((link) => (
                <li key={link.label}>
                  <Link to={link.to} className="text-white/70 hover:text-white text-sm transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}

        <div>
          <h5 className="font-black uppercase text-sm tracking-wider mb-3 text-brutal-red">Legal</h5>
          <ul className="space-y-2">
            <li><Link to="/terms" className="text-white/70 hover:text-white text-sm transition-colors">Termos de uso</Link></li>
            <li><Link to="/privacy" className="text-white/70 hover:text-white text-sm transition-colors">Política de privacidade</Link></li>
            <li><Link to="/cookies" className="text-white/70 hover:text-white text-sm transition-colors">Política de cookies</Link></li>
            <li><Link to="/lgpd" className="text-white/70 hover:text-white text-sm transition-colors">LGPD</Link></li>
          </ul>
        </div>
      </div>

      <div className="border-t border-white/20 py-4">
        <p className="text-center text-white/50 text-sm">
          © 2026 JaChegai. Todos os direitos reservados.
        </p>
      </div>
    </footer>
  )
}

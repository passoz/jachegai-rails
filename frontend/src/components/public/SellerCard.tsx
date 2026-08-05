import { Link } from 'react-router-dom'
import type { PublicSeller } from '../../types/public'
import Badge from '../ui/Badge'

interface SellerCardProps {
  seller: PublicSeller
}

export default function SellerCard({ seller }: SellerCardProps) {
  return (
    <Link
      to={`/sellers/${seller.id}`}
      className="block border-4 border-brutal-black rounded-[1.5rem] shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] bg-white p-6 hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-x-0.5 hover:-translate-y-0.5 transition-all"
    >
      <div className="flex items-start justify-between gap-2 mb-3">
        <h3 className="font-black italic text-xl text-brutal-black">{seller.name}</h3>
        {seller.moderation_state !== 'approved' && (
          <Badge status={seller.moderation_state} />
        )}
      </div>
      {seller.description && (
        <p className="text-black/60 text-sm line-clamp-3">{seller.description}</p>
      )}
      {seller.address_city && (
        <p className="mt-3 text-sm font-bold text-black/50">
          📍 {seller.address_city}
          {seller.address_state ? `, ${seller.address_state}` : ''}
        </p>
      )}
    </Link>
  )
}

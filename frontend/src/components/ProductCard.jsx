import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ShoppingCart, Plus, Minus } from 'lucide-react'
import StarRating from './StarRating'
import { useCart } from '../contexts/CartContext'
import { useAuth } from '../contexts/AuthContext'
import { useNavigate } from 'react-router-dom'

export default function ProductCard({ product }) {
  const { addToCart } = useCart()
  const { user } = useAuth()
  const navigate = useNavigate()
  const [qty, setQty] = useState(1)
  const [adding, setAdding] = useState(false)
  const [added, setAdded] = useState(false)

  const maxQty = product.stock

  const handleAdd = async () => {
    if (!user) { navigate('/login'); return }
    setAdding(true)
    try {
      await addToCart(product.id, qty)
      setAdded(true)
      setTimeout(() => setAdded(false), 1500)
    } catch (e) {
      alert(e.response?.data?.detail || 'Error al agregar al carrito')
    } finally {
      setAdding(false)
    }
  }

  return (
    <div className="card" style={{ display: 'flex', flexDirection: 'column', transition: 'box-shadow 0.2s' }}
      onMouseEnter={e => e.currentTarget.style.boxShadow = '0 4px 16px rgba(0,0,0,0.12)'}
      onMouseLeave={e => e.currentTarget.style.boxShadow = ''}
    >
      <Link to={`/products/${product.id}`}>
        <div style={{ aspectRatio: '1', overflow: 'hidden', background: '#f3f4f6' }}>
          <img
            src={product.image_url || 'https://via.placeholder.com/300x300?text=Sin+imagen'}
            alt={product.name}
            style={{ width: '100%', height: '100%', objectFit: 'cover', transition: 'transform 0.3s' }}
            onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
            onMouseLeave={e => e.currentTarget.style.transform = ''}
            onError={e => { e.target.src = 'https://via.placeholder.com/300x300?text=Sin+imagen' }}
          />
        </div>
      </Link>

      <div style={{ padding: '0.85rem', display: 'flex', flexDirection: 'column', gap: '0.4rem', flex: 1 }}>
        {product.brand && (
          <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 600 }}>
            {product.brand.name}
          </span>
        )}
        <Link to={`/products/${product.id}`}>
          <h3 style={{ fontSize: '0.9rem', fontWeight: 600, color: 'var(--text-dark)', lineHeight: 1.3 }}>
            {product.name}
          </h3>
        </Link>
        <StarRating rating={product.rating_avg} count={product.rating_count} />
        <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--secondary)', marginTop: '0.2rem' }}>
          S/ {parseFloat(product.price).toFixed(2)}
        </div>
        {product.stock <= 5 && product.stock > 0 && (
          <span style={{ fontSize: '0.75rem', color: 'var(--warning)', fontWeight: 600 }}>
            ¡Solo {product.stock} en stock!
          </span>
        )}
        {product.stock === 0 && (
          <span style={{ fontSize: '0.75rem', color: 'var(--error)', fontWeight: 600 }}>Sin stock</span>
        )}

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', border: '1.5px solid var(--border)', borderRadius: '6px', overflow: 'hidden' }}>
            <button
              onClick={() => setQty(q => Math.max(1, q - 1))}
              style={{ width: '28px', height: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9fafb' }}
            >
              <Minus size={12} />
            </button>
            <span style={{ width: '30px', textAlign: 'center', fontSize: '0.85rem', fontWeight: 600 }}>{qty}</span>
            <button
              onClick={() => setQty(q => Math.min(maxQty, q + 1))}
              style={{ width: '28px', height: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9fafb' }}
            >
              <Plus size={12} />
            </button>
          </div>
          <button
            onClick={handleAdd}
            disabled={adding || product.stock === 0}
            className="btn-primary"
            style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px', padding: '0.4rem 0.5rem', fontSize: '0.8rem', opacity: product.stock === 0 ? 0.5 : 1 }}
          >
            <ShoppingCart size={14} />
            {added ? '¡Agregado!' : adding ? '...' : 'Agregar'}
          </button>
        </div>
      </div>
    </div>
  )
}

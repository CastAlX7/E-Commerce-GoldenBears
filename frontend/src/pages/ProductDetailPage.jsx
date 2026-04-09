import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ShoppingCart, Zap, Plus, Minus, ArrowLeft } from 'lucide-react'
import api from '../api/client'
import StarRating from '../components/StarRating'
import { useCart } from '../contexts/CartContext'
import { useAuth } from '../contexts/AuthContext'

export default function ProductDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { addToCart } = useCart()
  const [product, setProduct] = useState(null)
  const [loading, setLoading] = useState(true)
  const [qty, setQty] = useState(1)
  const [adding, setAdding] = useState(false)

  useEffect(() => {
    api.get(`/products/${id}`)
      .then(r => setProduct(r.data))
      .catch(() => navigate('/'))
      .finally(() => setLoading(false))
  }, [id, navigate])

  const handleAdd = async () => {
    if (!user) { navigate('/login'); return }
    setAdding(true)
    try {
      await addToCart(product.id, qty)
      navigate('/cart')
    } catch (e) {
      alert(e.response?.data?.detail || 'Error al agregar al carrito')
    } finally {
      setAdding(false)
    }
  }

  const handleBuyNow = async () => {
    if (!user) { navigate('/login'); return }
    try {
      await addToCart(product.id, qty)
      navigate('/checkout')
    } catch (e) {
      alert(e.response?.data?.detail || 'Error')
    }
  }

  if (loading) return <div className="spinner" />
  if (!product) return null

  return (
    <div className="page-wrapper">
      <div className="container">
        <button onClick={() => navigate(-1)} style={{ display: 'flex', alignItems: 'center', gap: '4px', background: 'none', color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
          <ArrowLeft size={16} /> Volver
        </button>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2.5rem' }}>
          {/* Image */}
          <div className="card" style={{ aspectRatio: '1', overflow: 'hidden', padding: '1rem' }}>
            <img
              src={product.image_url || 'https://via.placeholder.com/500x500?text=Sin+imagen'}
              alt={product.name}
              style={{ width: '100%', height: '100%', objectFit: 'contain' }}
              onError={e => { e.target.src = 'https://via.placeholder.com/500x500?text=Sin+imagen' }}
            />
          </div>

          {/* Details */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {product.brand && (
              <span style={{ fontSize: '0.85rem', color: 'var(--primary)', fontWeight: 700, textTransform: 'uppercase' }}>
                {product.brand.name}
              </span>
            )}
            <h1 style={{ fontSize: '1.6rem', fontWeight: 700, lineHeight: 1.2 }}>{product.name}</h1>
            <StarRating rating={product.rating_avg} count={product.rating_count} />

            <div style={{ fontSize: '2rem', fontWeight: 800, color: 'var(--secondary)' }}>
              S/ {parseFloat(product.price).toFixed(2)}
            </div>

            {product.description && (
              <p style={{ color: 'var(--text-muted)', lineHeight: 1.7, fontSize: '0.95rem' }}>
                {product.description}
              </p>
            )}

            <div style={{ padding: '0.75rem', background: '#f0fdf4', borderRadius: '8px', fontSize: '0.9rem' }}>
              <strong>Stock disponible:</strong> {product.stock} unidades
            </div>

            {product.category && (
              <div style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>
                Categoría: <strong>{product.category.name}</strong>
              </div>
            )}

            {/* Qty selector */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', border: '2px solid var(--border)', borderRadius: '8px', overflow: 'hidden' }}>
                <button onClick={() => setQty(q => Math.max(1, q - 1))} style={{ width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9fafb', fontSize: '1.1rem' }}>
                  <Minus size={16} />
                </button>
                <span style={{ width: '50px', textAlign: 'center', fontWeight: 700, fontSize: '1.1rem' }}>{qty}</span>
                <button onClick={() => setQty(q => Math.min(product.stock, q + 1))} style={{ width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9fafb', fontSize: '1.1rem' }}>
                  <Plus size={16} />
                </button>
              </div>
              <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>máx. {product.stock}</span>
            </div>

            <div style={{ display: 'flex', gap: '0.75rem' }}>
              <button
                onClick={handleAdd}
                disabled={adding || product.stock === 0}
                className="btn-primary"
                style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', padding: '0.8rem', fontSize: '1rem', opacity: product.stock === 0 ? 0.5 : 1 }}
              >
                <ShoppingCart size={18} /> Agregar al carrito
              </button>
              <button
                onClick={handleBuyNow}
                disabled={product.stock === 0}
                className="btn-secondary"
                style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', padding: '0.8rem', fontSize: '1rem', opacity: product.stock === 0 ? 0.5 : 1 }}
              >
                <Zap size={18} /> Comprar ahora
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

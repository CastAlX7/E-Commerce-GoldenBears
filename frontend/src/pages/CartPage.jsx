import { Link, useNavigate } from 'react-router-dom'
import { Trash2, Plus, Minus, ShoppingBag } from 'lucide-react'
import { useCart } from '../contexts/CartContext'
import { useAuth } from '../contexts/AuthContext'

export default function CartPage() {
  const { cart, updateItem, removeItem } = useCart()
  const { user } = useAuth()
  const navigate = useNavigate()

  if (!user) {
    return (
      <div className="page-wrapper" style={{ textAlign: 'center', padding: '4rem' }}>
        <ShoppingBag size={48} style={{ color: 'var(--text-muted)', marginBottom: '1rem' }} />
        <p style={{ color: 'var(--text-muted)', marginBottom: '1rem' }}>Inicia sesión para ver tu carrito</p>
        <Link to="/login" className="btn-primary">Iniciar sesión</Link>
      </div>
    )
  }

  if (cart.items.length === 0) {
    return (
      <div className="page-wrapper" style={{ textAlign: 'center', padding: '4rem' }}>
        <ShoppingBag size={48} style={{ color: 'var(--text-muted)', marginBottom: '1rem' }} />
        <p style={{ color: 'var(--text-muted)', marginBottom: '1rem' }}>Tu carrito está vacío</p>
        <Link to="/" className="btn-primary">Explorar productos</Link>
      </div>
    )
  }

  return (
    <div className="page-wrapper">
      <div className="container">
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1.5rem' }}>Mi carrito</h1>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: '1.5rem', alignItems: 'start' }}>
          {/* Items */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {cart.items.map(item => (
              <div key={item.id} className="card" style={{ display: 'flex', gap: '1rem', padding: '1rem', alignItems: 'center' }}>
                <Link to={`/products/${item.product_id}`}>
                  <img
                    src={item.product.image_url || 'https://via.placeholder.com/80x80'}
                    alt={item.product.name}
                    style={{ width: '80px', height: '80px', objectFit: 'cover', borderRadius: '8px' }}
                    onError={e => { e.target.src = 'https://via.placeholder.com/80x80' }}
                  />
                </Link>
                <div style={{ flex: 1 }}>
                  <Link to={`/products/${item.product_id}`}>
                    <h3 style={{ fontWeight: 600, fontSize: '0.95rem' }}>{item.product.name}</h3>
                  </Link>
                  {item.product.brand && (
                    <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{item.product.brand.name}</p>
                  )}
                  <p style={{ fontWeight: 700, color: 'var(--secondary)', marginTop: '0.2rem' }}>
                    S/ {parseFloat(item.product.price).toFixed(2)}
                  </p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', border: '1.5px solid var(--border)', borderRadius: '6px', overflow: 'hidden' }}>
                    <button onClick={() => updateItem(item.product_id, item.quantity - 1)} style={{ width: '30px', height: '30px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9fafb' }}>
                      <Minus size={12} />
                    </button>
                    <span style={{ width: '36px', textAlign: 'center', fontWeight: 600, fontSize: '0.9rem' }}>{item.quantity}</span>
                    <button onClick={() => updateItem(item.product_id, item.quantity + 1)} style={{ width: '30px', height: '30px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9fafb' }}>
                      <Plus size={12} />
                    </button>
                  </div>
                  <div style={{ fontWeight: 700, color: 'var(--text-dark)', minWidth: '80px', textAlign: 'right' }}>
                    S/ {(parseFloat(item.product.price) * item.quantity).toFixed(2)}
                  </div>
                  <button onClick={() => removeItem(item.product_id)} style={{ background: 'none', color: 'var(--error)', padding: '4px' }}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>

          {/* Summary */}
          <div className="card" style={{ padding: '1.5rem', position: 'sticky', top: '80px' }}>
            <h2 style={{ fontWeight: 700, marginBottom: '1rem', fontSize: '1.1rem' }}>Resumen</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1rem' }}>
              {cart.items.map(item => (
                <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', color: 'var(--text-muted)' }}>
                  <span>{item.product.name} x{item.quantity}</span>
                  <span>S/ {(parseFloat(item.product.price) * item.quantity).toFixed(2)}</span>
                </div>
              ))}
            </div>
            <div style={{ borderTop: '1px solid var(--border)', paddingTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem' }}>
                <span>Subtotal</span>
                <span>S/ {parseFloat(cart.subtotal).toFixed(2)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                <span>IGV estimado (18%)</span>
                <span>S/ {(parseFloat(cart.subtotal) * 0.18).toFixed(2)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 800, fontSize: '1.1rem', marginTop: '0.4rem', paddingTop: '0.4rem', borderTop: '1px solid var(--border)' }}>
                <span>Estimado</span>
                <span>S/ {(parseFloat(cart.subtotal) * 1.18).toFixed(2)}</span>
              </div>
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '0.5rem' }}>
              Envío y comisión de pago calculados al finalizar la compra
            </p>
            <button onClick={() => navigate('/checkout')} className="btn-primary" style={{ width: '100%', padding: '0.85rem', fontSize: '1rem', marginTop: '1rem' }}>
              Finalizar compra
            </button>
            <Link to="/" style={{ display: 'block', textAlign: 'center', marginTop: '0.75rem', fontSize: '0.88rem', color: 'var(--primary)', fontWeight: 600 }}>
              Seguir comprando
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

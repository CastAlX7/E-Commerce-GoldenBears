import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { Package } from 'lucide-react'
import api from '../api/client'

export default function OrdersPage() {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/orders').then(r => setOrders(r.data)).catch(() => {}).finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="spinner" />

  return (
    <div className="page-wrapper">
      <div className="container" style={{ maxWidth: '800px' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1.5rem' }}>Mis pedidos</h1>
        {orders.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
            <Package size={48} style={{ marginBottom: '1rem' }} />
            <p>No tienes pedidos aún</p>
            <Link to="/" className="btn-primary" style={{ display: 'inline-block', marginTop: '1rem' }}>Ir a comprar</Link>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {orders.map(order => (
              <div key={order.id} className="card" style={{ padding: '1.25rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.4rem' }}>
                      <span style={{ fontWeight: 700, fontSize: '0.95rem' }}>#{order.tracking_id || order.id.slice(0, 8).toUpperCase()}</span>
                      <span style={{
                        padding: '2px 8px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600,
                        background: order.status === 'paid' ? '#d1fae5' : '#fef3c7',
                        color: order.status === 'paid' ? '#065f46' : '#92400e',
                      }}>
                        {order.status === 'paid' ? 'Pagado' : order.status}
                      </span>
                      <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', textTransform: 'capitalize' }}>{order.receipt_type}</span>
                    </div>
                    <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                      {new Date(order.created_at).toLocaleDateString('es-PE', { year: 'numeric', month: 'long', day: 'numeric' })}
                    </p>
                    <p style={{ fontSize: '0.85rem', marginTop: '0.3rem', color: 'var(--text-muted)' }}>
                      {order.items.length} producto{order.items.length !== 1 ? 's' : ''}
                    </p>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <p style={{ fontWeight: 800, fontSize: '1.1rem', color: 'var(--secondary)' }}>
                      S/ {parseFloat(order.total).toFixed(2)}
                    </p>
                    <Link to={`/orders/${order.id}`} style={{ fontSize: '0.85rem', color: 'var(--primary)', fontWeight: 600 }}>
                      Ver detalle →
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

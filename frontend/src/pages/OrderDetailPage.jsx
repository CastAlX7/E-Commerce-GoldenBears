import { useState, useEffect } from 'react'
import { useParams, useLocation, Link } from 'react-router-dom'
import { CheckCircle, ShoppingCart, Mail } from 'lucide-react'
import api from '../api/client'
import { useCart } from '../contexts/CartContext'

export default function OrderDetailPage() {
  const { id } = useParams()
  const location = useLocation()
  const { fetchCart } = useCart()
  const [order, setOrder] = useState(null)
  const [loading, setLoading] = useState(true)
  const [addingItem, setAddingItem] = useState(null)
  const [addedItems, setAddedItems] = useState({})
  const success = location.state?.success
  const emailSent = location.state?.email_sent
  const emailAddress = location.state?.email_address

  useEffect(() => {
    api.get(`/orders/${id}`).then(r => setOrder(r.data)).finally(() => setLoading(false))
  }, [id])

  const handleAddToCart = async (productId, quantity) => {
    setAddingItem(productId)
    try {
      await api.post('/cart/items', { product_id: productId, quantity })
      await fetchCart()
      setAddedItems(prev => ({ ...prev, [productId]: true }))
      setTimeout(() => setAddedItems(prev => ({ ...prev, [productId]: false })), 2000)
    } catch {
      alert('Error al agregar al carrito')
    } finally {
      setAddingItem(null)
    }
  }

  if (loading) return <div className="spinner" />
  if (!order) return <div style={{ textAlign: 'center', padding: '2rem' }}>Pedido no encontrado</div>

  return (
    <div className="page-wrapper">
      <div className="container" style={{ maxWidth: '760px' }}>
        {success && (
          <div className="alert alert-success" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '1rem' }}>
            <CheckCircle size={18} /> ¡Compra realizada exitosamente! Tu pedido está siendo procesado.
          </div>
        )}

        {success && emailSent && emailAddress && (
          <div className="alert" style={{
            display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '1.5rem',
            background: '#fff7ed', color: '#92400e',
            border: '1px solid #fed7aa', borderLeft: '4px solid #FF9900',
            borderRadius: '6px', padding: '12px 16px',
          }}>
            <Mail size={18} style={{ flexShrink: 0 }} />
            <span>Comprobante enviado a <strong>{emailAddress}</strong>. Revisa tu bandeja de entrada.</span>
          </div>
        )}

        <div style={{ marginBottom: '1.5rem' }}>
          <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Pedido #{order.tracking_id || order.id.slice(0, 8).toUpperCase()}</h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.88rem' }}>
            {new Date(order.created_at).toLocaleDateString('es-PE', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
          </p>
        </div>

        {/* Products */}
        <div className="card" style={{ padding: '1.25rem', marginBottom: '1rem' }}>
          <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '1rem' }}>Productos</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {order.items.map(item => (
              <div key={item.id} style={{ display: 'flex', gap: '0.85rem', alignItems: 'center' }}>
                <img
                  src={item.product.image_url || 'https://via.placeholder.com/60'}
                  alt={item.product.name}
                  style={{ width: '60px', height: '60px', objectFit: 'cover', borderRadius: '6px' }}
                  onError={e => { e.target.src = 'https://via.placeholder.com/60' }}
                />
                <div style={{ flex: 1 }}>
                  <Link to={`/products/${item.product_id}`} style={{ fontWeight: 600, fontSize: '0.9rem' }}>{item.product.name}</Link>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                    S/ {parseFloat(item.unit_price).toFixed(2)} x {item.quantity}
                  </p>
                </div>
                <span style={{ fontWeight: 700, marginRight: '0.75rem' }}>S/ {parseFloat(item.subtotal).toFixed(2)}</span>
                <button
                  onClick={() => handleAddToCart(item.product_id, item.quantity)}
                  disabled={addingItem === item.product_id}
                  style={{
                    display: 'flex', alignItems: 'center', gap: '4px',
                    padding: '6px 10px', borderRadius: '6px', fontSize: '0.78rem', fontWeight: 600,
                    border: '1.5px solid var(--primary)',
                    background: addedItems[item.product_id] ? 'var(--primary)' : '#fff',
                    color: addedItems[item.product_id] ? '#fff' : 'var(--primary)',
                    cursor: addingItem === item.product_id ? 'default' : 'pointer',
                    whiteSpace: 'nowrap',
                  }}
                >
                  <ShoppingCart size={13} />
                  {addingItem === item.product_id ? '...' : addedItems[item.product_id] ? '¡Agregado!' : 'Agregar'}
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Totals */}
        <div className="card" style={{ padding: '1.25rem', marginBottom: '1rem' }}>
          <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '1rem' }}>Resumen de pago</h2>
          {[
            ['Subtotal', `S/ ${parseFloat(order.subtotal).toFixed(2)}`],
            ['Envío', `S/ ${parseFloat(order.shipping_cost).toFixed(2)}`],
            ['IGV (18%)', `S/ ${parseFloat(order.tax_amount).toFixed(2)}`],
            ...(parseFloat(order.payment_fee) > 0 ? [['Comisión Visa (3.5%)', `S/ ${parseFloat(order.payment_fee).toFixed(2)}`]] : []),
          ].map(([label, value]) => (
            <div key={label} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem', marginBottom: '0.4rem' }}>
              <span style={{ color: 'var(--text-muted)' }}>{label}</span>
              <span>{value}</span>
            </div>
          ))}
          <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 800, fontSize: '1.2rem', marginTop: '0.75rem', paddingTop: '0.75rem', borderTop: '2px solid var(--border)' }}>
            <span>TOTAL</span>
            <span style={{ color: 'var(--secondary)' }}>S/ {parseFloat(order.total).toFixed(2)}</span>
          </div>
        </div>

        {/* Billing */}
        {order.billing_detail && (
          <div className="card" style={{ padding: '1.25rem', marginBottom: '1rem' }}>
            <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '0.75rem' }}>
              Datos de {order.receipt_type} — Ciudad: {order.shipping_city}
            </h2>
            {order.billing_detail.razon_social && <p style={{ fontSize: '0.9rem' }}><strong>Razón Social:</strong> {order.billing_detail.razon_social}</p>}
            {order.billing_detail.ruc && <p style={{ fontSize: '0.9rem' }}><strong>RUC:</strong> {order.billing_detail.ruc}</p>}
            {order.billing_detail.dni && <p style={{ fontSize: '0.9rem' }}><strong>DNI:</strong> {order.billing_detail.dni}</p>}
            {order.billing_detail.direccion_fiscal && <p style={{ fontSize: '0.9rem' }}><strong>Dirección:</strong> {order.billing_detail.direccion_fiscal}</p>}
          </div>
        )}

        <Link to="/orders" style={{ color: 'var(--primary)', fontWeight: 600, fontSize: '0.9rem' }}>← Volver a mis pedidos</Link>
      </div>
    </div>
  )
}

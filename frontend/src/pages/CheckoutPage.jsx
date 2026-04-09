import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Lock, CreditCard, Smartphone, Clock } from 'lucide-react'
import api from '../api/client'
import { useCart } from '../contexts/CartContext'

export default function CheckoutPage() {
  const navigate = useNavigate()
  const { cart, fetchCart } = useCart()
  const [step, setStep] = useState(1) // 1: shipping, 2: payment
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const [shippingCity, setShippingCity] = useState('Lima')
  const [receiptType, setReceiptType] = useState('boleta')
  const [billing, setBilling] = useState({ dni: '', razon_social: '', ruc: '', direccion_fiscal: '', billing_email: '' })
  const [payMethod, setPayMethod] = useState('card')
  const [card, setCard] = useState({ number: '', expiry: '', cvv: '' })
  const [yapePhone, setYapePhone] = useState('')
  const [timeLeft, setTimeLeft] = useState(null)
  const expiresAtRef = useRef(null)
  const timerRef = useRef(null)

  useEffect(() => {
    if (step !== 2 || !expiresAtRef.current) return
    timerRef.current = setInterval(() => {
      const remaining = Math.max(0, Math.floor((expiresAtRef.current - Date.now()) / 1000))
      setTimeLeft(remaining)
      if (remaining === 0) {
        clearInterval(timerRef.current)
        fetchCart()
        navigate('/')
      }
    }, 1000)
    return () => clearInterval(timerRef.current)
  }, [step])

  const initiate = async () => {
    setError('')
    setLoading(true)
    try {
      const { data } = await api.post('/orders/checkout/initiate', {
        shipping_city: shippingCity,
        receipt_type: receiptType,
      })
      setSummary(data)
      expiresAtRef.current = Date.now() + data.lock_expires_in_minutes * 60 * 1000
      setTimeLeft(data.lock_expires_in_minutes * 60)
      setStep(2)
    } catch (e) {
      setError(e.response?.data?.detail || 'Error al reservar stock')
    } finally {
      setLoading(false)
    }
  }

  const confirm = async () => {
    setError('')
    setLoading(true)
    try {
      const cleanBilling = Object.fromEntries(
        Object.entries(billing).map(([k, v]) => [k, v === '' ? null : v])
      )
      const { data } = await api.post('/orders/checkout/confirm', {
        shipping_city: shippingCity,
        receipt_type: receiptType,
        billing: cleanBilling,
        payment: {
          method: payMethod,
          card_number: payMethod === 'card' ? card.number : null,
          card_expiry: payMethod === 'card' ? card.expiry : null,
          card_cvv: payMethod === 'card' ? card.cvv : null,
          yape_phone: payMethod === 'yape_plin' ? yapePhone : null,
        },
      })
      await fetchCart()
      navigate(`/orders/${data.id}`, { state: { success: true } })
    } catch (e) {
      setError(e.response?.data?.detail || 'Error al confirmar compra')
    } finally {
      setLoading(false)
    }
  }

  if (cart.items.length === 0 && !summary) {
    navigate('/cart')
    return null
  }

  const items = summary ? summary.items : cart.items.map(i => ({
    name: i.product.name,
    image_url: i.product.image_url,
    quantity: i.quantity,
    unit_price: parseFloat(i.product.price),
    subtotal: parseFloat(i.product.price) * i.quantity,
  }))

  return (
    <div className="page-wrapper">
      <div className="container" style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: '1.5rem', alignItems: 'start' }}>
        <div>
          <h1 style={{ fontSize: '1.4rem', fontWeight: 700, marginBottom: '1.5rem' }}>
            {step === 1 ? '1. Datos de envío' : '2. Pago & Facturación'}
          </h1>

          {error && <div className="alert alert-error">{error}</div>}

          {step === 2 && summary && timeLeft !== null && (
            <div className="alert alert-warning" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Lock size={16} /> Stock reservado. Completa el pago antes de que expire el tiempo.
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 700, fontSize: '1rem', color: timeLeft <= 60 ? '#dc2626' : 'inherit' }}>
                <Clock size={16} />
                {String(Math.floor(timeLeft / 60)).padStart(2, '0')}:{String(timeLeft % 60).padStart(2, '0')}
              </span>
            </div>
          )}

          {step === 1 && (
            <div className="card" style={{ padding: '1.5rem' }}>
              <div className="form-group">
                <label>Ciudad de entrega</label>
                <select value={shippingCity} onChange={e => setShippingCity(e.target.value)}>
                  <option value="Lima">Lima (24-48h)</option>
                  <option value="Arequipa">Arequipa (5 días hábiles)</option>
                  <option value="Trujillo">Trujillo (5 días hábiles)</option>
                  <option value="Cusco">Cusco (5 días hábiles)</option>
                  <option value="Piura">Piura (5 días hábiles)</option>
                  <option value="Otra">Otra ciudad (5 días hábiles)</option>
                </select>
              </div>
              <div className="form-group">
                <label>Tipo de comprobante</label>
                <div style={{ display: 'flex', gap: '1rem' }}>
                  {['boleta', 'factura'].map(t => (
                    <button
                      key={t}
                      onClick={() => setReceiptType(t)}
                      style={{
                        flex: 1, padding: '0.7rem', borderRadius: '8px', fontWeight: 600, fontSize: '0.95rem',
                        border: `2px solid ${receiptType === t ? 'var(--primary)' : 'var(--border)'}`,
                        background: receiptType === t ? '#fff7ed' : '#fff',
                        color: receiptType === t ? 'var(--primary)' : 'var(--text-dark)',
                        textTransform: 'capitalize',
                      }}
                    >
                      {t.charAt(0).toUpperCase() + t.slice(1)}
                    </button>
                  ))}
                </div>
              </div>
              <button onClick={initiate} disabled={loading} className="btn-primary" style={{ width: '100%', padding: '0.85rem', fontSize: '1rem', marginTop: '0.5rem' }}>
                {loading ? 'Reservando stock...' : 'Continuar al pago →'}
              </button>
            </div>
          )}

          {step === 2 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {/* Receipt type */}
              <div className="card" style={{ padding: '1.5rem' }}>
                <h3 style={{ fontWeight: 700, marginBottom: '1rem', fontSize: '0.95rem', textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em' }}>Tipo de comprobante</h3>
                <div style={{ display: 'flex', gap: '1rem', marginBottom: receiptType === 'factura' ? '1rem' : 0 }}>
                  {['boleta', 'factura'].map(t => (
                    <button
                      key={t}
                      onClick={() => setReceiptType(t)}
                      style={{
                        flex: 1, padding: '0.7rem', borderRadius: '8px', fontWeight: 600, fontSize: '0.95rem',
                        border: `2px solid ${receiptType === t ? 'var(--primary)' : 'var(--border)'}`,
                        background: receiptType === t ? '#fff7ed' : '#fff',
                        color: receiptType === t ? 'var(--primary)' : 'var(--text-dark)',
                        textTransform: 'capitalize',
                      }}
                    >
                      {t.charAt(0).toUpperCase() + t.slice(1)}
                    </button>
                  ))}
                </div>
                {receiptType === 'boleta' && (
                  <div className="form-group" style={{ marginBottom: 0, marginTop: '1rem' }}>
                    <label>DNI (opcional)</label>
                    <input value={billing.dni} onChange={e => setBilling(b => ({ ...b, dni: e.target.value }))} placeholder="12345678" maxLength={8} />
                  </div>
                )}
                {receiptType === 'factura' && (
                  <>
                    <div className="form-group">
                      <label>Razón Social *</label>
                      <input value={billing.razon_social} onChange={e => setBilling(b => ({ ...b, razon_social: e.target.value }))} placeholder="Mi Empresa S.A.C." required />
                    </div>
                    <div className="form-group">
                      <label>RUC * (11 dígitos)</label>
                      <input value={billing.ruc} onChange={e => setBilling(b => ({ ...b, ruc: e.target.value }))} placeholder="20123456789" maxLength={11} required />
                    </div>
                    <div className="form-group">
                      <label>Dirección Fiscal *</label>
                      <input value={billing.direccion_fiscal} onChange={e => setBilling(b => ({ ...b, direccion_fiscal: e.target.value }))} placeholder="Av. Principal 123, Lima" required />
                    </div>
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label>Email de facturación</label>
                      <input type="email" value={billing.billing_email} onChange={e => setBilling(b => ({ ...b, billing_email: e.target.value }))} placeholder="billing@empresa.com" />
                    </div>
                  </>
                )}
              </div>

              {/* Payment method */}
              <div className="card" style={{ padding: '1.5rem' }}>
                <h3 style={{ fontWeight: 700, marginBottom: '1rem', fontSize: '0.95rem', textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em' }}>Método de pago</h3>
                <div style={{ display: 'flex', gap: '1rem', marginBottom: '1rem' }}>
                  <button
                    onClick={() => setPayMethod('card')}
                    style={{
                      flex: 1, padding: '0.8rem', borderRadius: '8px', fontWeight: 600, fontSize: '0.9rem',
                      border: `2px solid ${payMethod === 'card' ? 'var(--primary)' : 'var(--border)'}`,
                      background: payMethod === 'card' ? '#fff7ed' : '#fff',
                      display: 'flex', alignItems: 'center', gap: '8px', justifyContent: 'center',
                    }}
                  >
                    <CreditCard size={16} /> Tarjeta Visa
                  </button>
                  <button
                    onClick={() => setPayMethod('yape_plin')}
                    style={{
                      flex: 1, padding: '0.8rem', borderRadius: '8px', fontWeight: 600, fontSize: '0.9rem',
                      border: `2px solid ${payMethod === 'yape_plin' ? 'var(--primary)' : 'var(--border)'}`,
                      background: payMethod === 'yape_plin' ? '#fff7ed' : '#fff',
                      display: 'flex', alignItems: 'center', gap: '8px', justifyContent: 'center',
                    }}
                  >
                    <Smartphone size={16} /> Yape / Plin
                  </button>
                </div>

                {payMethod === 'card' && (
                  <>
                    <div className="form-group">
                      <label>Número de tarjeta</label>
                      <input
                        value={card.number}
                        onChange={e => setCard(c => ({ ...c, number: e.target.value.replace(/\D/g, '').slice(0, 16) }))}
                        placeholder="0000 0000 0000 0000"
                        maxLength={16}
                      />
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                      <div className="form-group" style={{ marginBottom: 0 }}>
                        <label>Fecha de expiración</label>
                        <input value={card.expiry} onChange={e => setCard(c => ({ ...c, expiry: e.target.value }))} placeholder="MM/YY" maxLength={5} />
                      </div>
                      <div className="form-group" style={{ marginBottom: 0 }}>
                        <label>CVV</label>
                        <input type="password" value={card.cvv} onChange={e => setCard(c => ({ ...c, cvv: e.target.value }))} placeholder="•••" maxLength={4} />
                      </div>
                    </div>
                    <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '0.75rem', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Lock size={12} /> Tu pago está cifrado y tokenizado por GOLDEN BEARS secure gateway.
                    </p>
                  </>
                )}

                {payMethod === 'yape_plin' && (
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label>Número de teléfono Yape/Plin</label>
                    <input value={yapePhone} onChange={e => setYapePhone(e.target.value)} placeholder="9XX XXX XXX" maxLength={9} />
                  </div>
                )}
              </div>

              <button onClick={confirm} disabled={loading} className="btn-primary" style={{ width: '100%', padding: '1rem', fontSize: '1.05rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                {loading ? 'Procesando...' : <><Lock size={16} /> Confirmar compra</>}
              </button>
            </div>
          )}
        </div>

        {/* Order summary sidebar */}
        <div className="card" style={{ padding: '1.5rem', position: 'sticky', top: '80px' }}>
          <h2 style={{ fontWeight: 700, marginBottom: '1rem', fontSize: '1rem' }}>Resumen del pedido</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginBottom: '1rem' }}>
            {items.map((item, i) => (
              <div key={i} style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                <img
                  src={item.image_url || 'https://via.placeholder.com/50'}
                  alt={item.name}
                  style={{ width: '50px', height: '50px', objectFit: 'cover', borderRadius: '6px' }}
                  onError={e => { e.target.src = 'https://via.placeholder.com/50' }}
                />
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: '0.85rem', fontWeight: 500 }}>{item.name}</p>
                  <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Cant: {item.quantity}</p>
                </div>
                <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>S/ {parseFloat(item.subtotal).toFixed(2)}</span>
              </div>
            ))}
          </div>
          <div style={{ borderTop: '1px solid var(--border)', paddingTop: '0.75rem', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem' }}>
              <span>Subtotal</span>
              <span>S/ {summary ? parseFloat(summary.subtotal).toFixed(2) : parseFloat(cart.subtotal).toFixed(2)}</span>
            </div>
            {summary && (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Envío ({summary.estimated_delivery})</span>
                  <span style={{ color: 'var(--primary)' }}>S/ {parseFloat(summary.shipping_cost).toFixed(2)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem' }}>
                  <span>IGV (18%)</span>
                  <span>S/ {parseFloat(summary.tax_amount).toFixed(2)}</span>
                </div>
              </>
            )}
            <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 800, fontSize: '1.2rem', marginTop: '0.4rem', paddingTop: '0.4rem', borderTop: '2px solid var(--border)' }}>
              <span>TOTAL</span>
              <span>S/ {summary ? parseFloat(summary.total).toFixed(2) : parseFloat(cart.subtotal).toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

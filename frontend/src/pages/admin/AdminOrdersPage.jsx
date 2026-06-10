import { useState, useEffect } from 'react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

const STATUS_COLORS = {
  paid:      { bg: '#d1fae5', color: '#065f46', label: 'Pagado' },
  pending:   { bg: '#fef3c7', color: '#92400e', label: 'Pendiente' },
  shipped:   { bg: '#dbeafe', color: '#1e40af', label: 'Enviado' },
  delivered: { bg: '#ede9fe', color: '#5b21b6', label: 'Entregado' },
  cancelled: { bg: '#f3f4f6', color: '#6b7280', label: 'Cancelado' },
}

const NEXT_STATUSES = {
  pending:   ['cancelled'],
  paid:      ['shipped', 'cancelled'],
  shipped:   ['delivered'],
  delivered: [],
  cancelled: [],
}

export default function AdminOrdersPage() {
  const [data, setData] = useState({ items: [], total: 0, page: 1, pages: 1 })
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [updating, setUpdating] = useState(null)

  const fetchOrders = () => {
    setLoading(true)
    api.get('/admin/orders', { params: { page, size: 20 } })
      .then(r => setData(r.data))
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchOrders() }, [page])

  const handleStatusChange = async (orderId, newStatus) => {
    setUpdating(orderId)
    try {
      await api.patch(`/admin/orders/${orderId}/status`, { status: newStatus })
      fetchOrders()
    } catch (e) {
      alert(e.response?.data?.detail || 'Error al actualizar estado')
    } finally {
      setUpdating(null)
    }
  }

  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 64px)' }}>
      <AdminSidebar />
      <main style={{ flex: 1, padding: '2rem', overflow: 'auto' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.25rem' }}>Pedidos</h1>
        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
          Todos los pedidos de la plataforma.
        </p>

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem 1.25rem', borderBottom: '1px solid var(--border)' }}>
            <h2 style={{ fontWeight: 700, fontSize: '1rem' }}>Todos los pedidos</h2>
            <span style={{ background: 'var(--primary)', color: '#fff', padding: '2px 10px', borderRadius: '20px', fontSize: '0.8rem', fontWeight: 600 }}>
              {data.total} TOTAL
            </span>
          </div>

          {loading ? <div className="spinner" /> : (
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border)' }}>
                  {['ID / Tracking', 'Cliente', 'Ciudad', 'Comprobante', 'Estado', 'Actualizar', 'Total', 'Fecha'].map(h => (
                    <th key={h} style={{ padding: '0.65rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em' }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.items.map(order => {
                  const s = STATUS_COLORS[order.status] || STATUS_COLORS.pending
                  const next = NEXT_STATUSES[order.status] || []
                  const isUpdating = updating === order.id
                  return (
                    <tr key={order.id} style={{ borderBottom: '1px solid var(--border)' }}>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        <p style={{ fontWeight: 600, fontSize: '0.82rem', fontFamily: 'monospace' }}>{order.tracking_id || '—'}</p>
                        <p style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{order.items_count} ítem(s)</p>
                      </td>
                      <td style={{ padding: '0.75rem 1rem', fontSize: '0.85rem' }}>{order.customer_email}</td>
                      <td style={{ padding: '0.75rem 1rem', fontSize: '0.85rem' }}>{order.shipping_city}</td>
                      <td style={{ padding: '0.75rem 1rem', fontSize: '0.85rem', textTransform: 'capitalize' }}>{order.receipt_type}</td>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        <span style={{ padding: '3px 8px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600, background: s.bg, color: s.color }}>
                          {s.label}
                        </span>
                      </td>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        {next.length > 0 ? (
                          <select
                            disabled={isUpdating}
                            defaultValue=""
                            onChange={e => { if (e.target.value) handleStatusChange(order.id, e.target.value) }}
                            style={{ fontSize: '0.78rem', padding: '3px 6px', borderRadius: '4px', border: '1px solid var(--border)', cursor: 'pointer', opacity: isUpdating ? 0.5 : 1 }}
                          >
                            <option value="" disabled>Cambiar…</option>
                            {next.map(ns => (
                              <option key={ns} value={ns}>{STATUS_COLORS[ns]?.label || ns}</option>
                            ))}
                          </select>
                        ) : (
                          <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>—</span>
                        )}
                      </td>
                      <td style={{ padding: '0.75rem 1rem', fontWeight: 700, fontSize: '0.9rem' }}>
                        S/ {parseFloat(order.total).toFixed(2)}
                      </td>
                      <td style={{ padding: '0.75rem 1rem', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                        {new Date(order.created_at).toLocaleDateString('es-PE')}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem 1.25rem', borderTop: '1px solid var(--border)', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
            <span>Mostrando {data.items.length} de {data.total} pedidos</span>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} style={{ padding: '4px 10px', borderRadius: '4px', border: '1px solid var(--border)', background: page <= 1 ? '#f9fafb' : '#fff', cursor: page <= 1 ? 'default' : 'pointer' }}>‹</button>
              <button onClick={() => setPage(p => Math.min(data.pages, p + 1))} disabled={page >= data.pages} style={{ padding: '4px 10px', borderRadius: '4px', border: '1px solid var(--border)', background: page >= data.pages ? '#f9fafb' : '#fff', cursor: page >= data.pages ? 'default' : 'pointer' }}>›</button>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}

import { useState, useEffect } from 'react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

export default function AdminClientsPage() {
  const [data, setData] = useState({ items: [], total: 0, page: 1, pages: 1 })
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)

  useEffect(() => {
    setLoading(true)
    api.get('/admin/clients', { params: { page, size: 20 } })
      .then(r => setData(r.data))
      .finally(() => setLoading(false))
  }, [page])

  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 64px)' }}>
      <AdminSidebar />
      <main style={{ flex: 1, padding: '2rem', overflow: 'auto' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.25rem' }}>Clientes</h1>
        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
          Usuarios registrados en la plataforma.
        </p>

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem 1.25rem', borderBottom: '1px solid var(--border)' }}>
            <h2 style={{ fontWeight: 700, fontSize: '1rem' }}>Todos los clientes</h2>
            <span style={{ background: 'var(--primary)', color: '#fff', padding: '2px 10px', borderRadius: '20px', fontSize: '0.8rem', fontWeight: 600 }}>
              {data.total} TOTAL
            </span>
          </div>

          {loading ? <div className="spinner" /> : (
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border)' }}>
                  {['Email', 'Estado', 'Pedidos', 'Total gastado', 'Registrado'].map(h => (
                    <th key={h} style={{ padding: '0.65rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em' }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.items.map(client => (
                  <tr key={client.id} style={{ borderBottom: '1px solid var(--border)' }}>
                    <td style={{ padding: '0.75rem 1rem', fontWeight: 500, fontSize: '0.88rem' }}>{client.email}</td>
                    <td style={{ padding: '0.75rem 1rem' }}>
                      <span style={{
                        padding: '3px 8px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600,
                        background: client.is_active ? '#d1fae5' : '#f3f4f6',
                        color: client.is_active ? '#065f46' : '#6b7280',
                      }}>
                        {client.is_active ? 'Activo' : 'Inactivo'}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.88rem', fontWeight: 600 }}>{client.orders_count}</td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.88rem', fontWeight: 700, color: 'var(--primary)' }}>
                      S/ {parseFloat(client.total_spent).toFixed(2)}
                    </td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      {new Date(client.created_at).toLocaleDateString('es-PE')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem 1.25rem', borderTop: '1px solid var(--border)', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
            <span>Mostrando {data.items.length} de {data.total} clientes</span>
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

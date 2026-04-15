import { useState, useEffect } from 'react'
import { Eye, EyeOff, Trash2 } from 'lucide-react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

export default function AdminClientsPage() {
  const [data, setData] = useState({ items: [], total: 0, page: 1, pages: 1 })
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [confirmDelete, setConfirmDelete] = useState(null)
  const [deleteError, setDeleteError] = useState('')
  const [deleting, setDeleting] = useState(false)

  const fetchClients = () => {
    setLoading(true)
    api.get('/admin/clients', { params: { page, size: 20 } })
      .then(r => setData(r.data))
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchClients() }, [page])

  const toggleActive = async (client) => {
    try {
      await api.patch(`/admin/clients/${client.id}/toggle`)
      fetchClients()
    } catch {}
  }

  const handleDeleteConfirm = async () => {
    if (!confirmDelete) return
    setDeleting(true)
    setDeleteError('')
    try {
      await api.delete(`/admin/clients/${confirmDelete.id}`)
      setConfirmDelete(null)
      fetchClients()
    } catch (e) {
      setDeleteError(e.response?.data?.detail || 'Error al eliminar el cliente')
    } finally {
      setDeleting(false)
    }
  }

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
                  {['Email', 'Estado', 'Pedidos', 'Total gastado', 'Registrado', 'Acciones'].map(h => (
                    <th key={h} style={{ padding: '0.65rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em' }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.items.map(client => (
                  <tr key={client.id} style={{ borderBottom: '1px solid var(--border)', opacity: client.is_active ? 1 : 0.6 }}>
                    <td style={{ padding: '0.75rem 1rem', fontWeight: 500, fontSize: '0.88rem' }}>{client.email}</td>
                    <td style={{ padding: '0.75rem 1rem' }}>
                      <span style={{
                        padding: '3px 8px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600,
                        background: client.is_active ? '#d1fae5' : '#f3f4f6',
                        color: client.is_active ? '#065f46' : '#6b7280',
                        display: 'flex', alignItems: 'center', gap: '4px', width: 'fit-content',
                      }}>
                        <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: client.is_active ? '#10b981' : '#9ca3af' }} />
                        {client.is_active ? 'Activo' : 'Suspendido'}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.88rem', fontWeight: 600 }}>{client.orders_count}</td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.88rem', fontWeight: 700, color: 'var(--primary)' }}>
                      S/ {parseFloat(client.total_spent).toFixed(2)}
                    </td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      {new Date(client.created_at).toLocaleDateString('es-PE')}
                    </td>
                    <td style={{ padding: '0.75rem 1rem' }}>
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <button
                          onClick={() => toggleActive(client)}
                          title={client.is_active ? 'Suspender cuenta' : 'Activar cuenta'}
                          style={{ background: 'none', padding: '4px', color: client.is_active ? 'var(--text-muted)' : 'var(--success)' }}
                        >
                          {client.is_active ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                        <button
                          onClick={() => { setConfirmDelete(client); setDeleteError('') }}
                          title="Eliminar cliente"
                          style={{ background: 'none', padding: '4px', color: '#ef4444' }}
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
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

      {/* Modal eliminar cliente */}
      {confirmDelete && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="card" style={{ width: '100%', maxWidth: '420px', padding: '1.75rem', margin: '1rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
              <div style={{ background: '#fee2e2', borderRadius: '50%', padding: '8px', display: 'flex' }}>
                <Trash2 size={20} color="#ef4444" />
              </div>
              <h3 style={{ fontWeight: 700, fontSize: '1rem' }}>Eliminar cliente</h3>
            </div>
            <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>
              ¿Estás seguro de eliminar permanentemente la cuenta de:
            </p>
            <p style={{ fontWeight: 600, fontSize: '0.95rem', marginBottom: '1rem' }}>
              {confirmDelete.email}
            </p>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '1.25rem', background: '#fef9c3', padding: '0.6rem 0.75rem', borderRadius: '6px', border: '1px solid #fde047' }}>
              Esta acción no se puede deshacer. Si el cliente tiene pedidos asociados no podrá eliminarse — suspende su cuenta en su lugar.
            </p>
            {deleteError && (
              <div className="alert alert-error" style={{ marginBottom: '1rem', fontSize: '0.85rem' }}>{deleteError}</div>
            )}
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button onClick={() => { setConfirmDelete(null); setDeleteError('') }} disabled={deleting} className="btn-secondary" style={{ padding: '0.6rem 1.2rem' }}>
                Cancelar
              </button>
              <button onClick={handleDeleteConfirm} disabled={deleting} style={{ padding: '0.6rem 1.2rem', background: '#ef4444', color: '#fff', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: deleting ? 'default' : 'pointer', opacity: deleting ? 0.7 : 1 }}>
                {deleting ? 'Eliminando...' : 'Sí, eliminar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

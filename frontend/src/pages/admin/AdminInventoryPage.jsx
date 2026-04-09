import { useState, useEffect } from 'react'
import { Eye, EyeOff, Edit, Plus } from 'lucide-react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

export default function AdminInventoryPage() {
  const [products, setProducts] = useState({ items: [], total: 0, page: 1, pages: 1 })
  const [categories, setCategories] = useState([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [form, setForm] = useState({ name: '', description: '', price: '', stock: '', category_id: '', image_url: '' })
  const [editId, setEditId] = useState(null)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState('')

  const fetchProducts = () => {
    setLoading(true)
    api.get('/products', { params: { page, size: 10, enabled_only: false } })
      .then(r => setProducts(r.data))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    fetchProducts()
    api.get('/categories').then(r => setCategories(r.data)).catch(() => {})
  }, [page])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSaving(true)
    setMsg('')
    try {
      const payload = {
        name: form.name,
        description: form.description || null,
        price: parseFloat(form.price),
        stock: parseInt(form.stock),
        category_id: form.category_id ? parseInt(form.category_id) : null,
        image_url: form.image_url || null,
      }
      if (editId) {
        await api.put(`/products/${editId}`, payload)
        setMsg('Producto actualizado')
        setEditId(null)
      } else {
        await api.post('/products', payload)
        setMsg('Producto creado')
      }
      setForm({ name: '', description: '', price: '', stock: '', category_id: '', image_url: '' })
      fetchProducts()
    } catch (e) {
      setMsg(e.response?.data?.detail || 'Error al guardar')
    } finally {
      setSaving(false)
    }
  }

  const toggleEnabled = async (product) => {
    try {
      await api.put(`/products/${product.id}`, { is_enabled: !product.is_enabled })
      fetchProducts()
    } catch {}
  }

  const startEdit = (product) => {
    setEditId(product.id)
    setForm({
      name: product.name,
      description: product.description || '',
      price: String(product.price),
      stock: String(product.stock),
      category_id: product.category_id ? String(product.category_id) : '',
      image_url: product.image_url || '',
    })
    window.scrollTo(0, 0)
  }

  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 64px)' }}>
      <AdminSidebar />

      {/* Main */}
      <main style={{ flex: 1, padding: '2rem', overflow: 'auto' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.25rem' }}>Inventario de Productos</h1>
        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
          Administra tu catálogo, niveles de stock y disponibilidad de productos.
        </p>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: '1.5rem', alignItems: 'start' }}>
          {/* Table */}
          <div className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem 1.25rem', borderBottom: '1px solid var(--border)' }}>
              <div>
                <h2 style={{ fontWeight: 700, fontSize: '1rem' }}>Inventario en vivo</h2>
              </div>
              <span style={{ background: 'var(--primary)', color: '#fff', padding: '2px 10px', borderRadius: '20px', fontSize: '0.8rem', fontWeight: 600 }}>
                {products.total} TOTAL
              </span>
            </div>
            {loading ? <div className="spinner" /> : (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border)' }}>
                    {['Info del producto', 'Stock', 'Estado', 'Acciones'].map(h => (
                      <th key={h} style={{ padding: '0.65rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)', letterSpacing: '0.05em' }}>
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {products.items.map(product => (
                    <tr key={product.id} style={{ borderBottom: '1px solid var(--border)', opacity: product.is_enabled ? 1 : 0.6 }}>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                          <img
                            src={product.image_url || 'https://via.placeholder.com/40'}
                            alt={product.name}
                            style={{ width: '40px', height: '40px', objectFit: 'cover', borderRadius: '6px' }}
                            onError={e => { e.target.src = 'https://via.placeholder.com/40' }}
                          />
                          <div>
                            <p style={{ fontWeight: 600, fontSize: '0.88rem', color: product.is_enabled ? 'var(--text-dark)' : 'var(--text-muted)' }}>{product.name}</p>
                            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                              {product.category?.name || 'Sin categoría'} • S/ {parseFloat(product.price).toFixed(2)}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        <div>
                          <span style={{ fontWeight: 700, fontSize: '1rem' }}>{product.stock}</span>
                          {product.stock > 0 && product.stock <= 10 && (
                            <p style={{ fontSize: '0.7rem', color: 'var(--warning)', fontWeight: 600 }}>Stock bajo pronto</p>
                          )}
                        </div>
                      </td>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        <span style={{
                          padding: '3px 8px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600,
                          background: product.is_enabled ? '#d1fae5' : '#f3f4f6',
                          color: product.is_enabled ? '#065f46' : '#6b7280',
                          display: 'flex', alignItems: 'center', gap: '4px', width: 'fit-content',
                        }}>
                          <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: product.is_enabled ? '#10b981' : '#9ca3af' }} />
                          {product.is_enabled ? 'Activo' : 'Deshabilitado'}
                        </span>
                      </td>
                      <td style={{ padding: '0.75rem 1rem' }}>
                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                          <button onClick={() => startEdit(product)} title="Editar" style={{ background: 'none', padding: '4px', color: 'var(--secondary)' }}>
                            <Edit size={16} />
                          </button>
                          <button onClick={() => toggleEnabled(product)} title={product.is_enabled ? 'Deshabilitar' : 'Habilitar'} style={{ background: 'none', padding: '4px', color: product.is_enabled ? 'var(--text-muted)' : 'var(--success)' }}>
                            {product.is_enabled ? <EyeOff size={16} /> : <Eye size={16} />}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
            {/* Pagination */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem 1.25rem', borderTop: '1px solid var(--border)', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              <span>Mostrando {products.items.length} de {products.total} productos</span>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} style={{ padding: '4px 10px', borderRadius: '4px', border: '1px solid var(--border)', background: page <= 1 ? '#f9fafb' : '#fff', cursor: page <= 1 ? 'default' : 'pointer' }}>‹</button>
                <button onClick={() => setPage(p => Math.min(products.pages, p + 1))} disabled={page >= products.pages} style={{ padding: '4px 10px', borderRadius: '4px', border: '1px solid var(--border)', background: page >= products.pages ? '#f9fafb' : '#fff', cursor: page >= products.pages ? 'default' : 'pointer' }}>›</button>
              </div>
            </div>
          </div>

          {/* Form */}
          <div className="card" style={{ padding: '1.25rem' }}>
            <h2 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '0.25rem' }}>
              {editId ? '✏️ Editar Producto' : 'Registrar Nuevo Producto'}
            </h2>
            <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              {editId ? 'Modificar datos del producto' : 'Agregar ítems al catálogo global'}
            </p>
            {msg && <div className={`alert ${msg.includes('Error') ? 'alert-error' : 'alert-success'}`}>{msg}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Nombre del producto *</label>
                <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="Ej. Classic Bear Watch" required />
              </div>
              <div className="form-group">
                <label>Descripción</label>
                <textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} placeholder="Describe las características clave..." rows={3} style={{ resize: 'vertical' }} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div className="form-group">
                  <label>Precio (S/) *</label>
                  <input type="number" step="0.01" min="0" value={form.price} onChange={e => setForm(f => ({ ...f, price: e.target.value }))} placeholder="0.00" required />
                </div>
                <div className="form-group">
                  <label>Stock inicial *</label>
                  <input type="number" min="0" value={form.stock} onChange={e => setForm(f => ({ ...f, stock: e.target.value }))} placeholder="0" required />
                </div>
              </div>
              <div className="form-group">
                <label>Categoría</label>
                <select value={form.category_id} onChange={e => setForm(f => ({ ...f, category_id: e.target.value }))}>
                  <option value="">Seleccionar categoría</option>
                  {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>URL de imagen</label>
                <input value={form.image_url} onChange={e => setForm(f => ({ ...f, image_url: e.target.value }))} placeholder="https://..." />
              </div>
              <div style={{ display: 'flex', gap: '0.75rem' }}>
                <button type="submit" disabled={saving} className="btn-primary" style={{ flex: 1, padding: '0.75rem', fontSize: '0.9rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
                  {saving ? 'Guardando...' : editId ? <><Edit size={14} /> Actualizar producto</> : <><Plus size={14} /> Guardar en catálogo</>}
                </button>
                {editId && (
                  <button type="button" onClick={() => { setEditId(null); setForm({ name: '', description: '', price: '', stock: '', category_id: '', image_url: '' }) }} className="btn-secondary" style={{ padding: '0.75rem' }}>
                    Cancelar
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      </main>
    </div>
  )
}

import { useState, useEffect } from 'react'
import { Plus, Edit, Trash2, X, Tag, Layers } from 'lucide-react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

function CrudSection({ title, icon: Icon, items, onAdd, onEdit, onDelete, renderItem, form, setForm, editId, saving, msg, onSubmit, onCancel, formFields }) {
  return (
    <div className="card" style={{ padding: '1.25rem', marginBottom: '1.5rem' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem', paddingBottom: '0.75rem', borderBottom: '1px solid var(--border)' }}>
        <Icon size={18} color="var(--primary)" />
        <h2 style={{ fontWeight: 700, fontSize: '1rem' }}>{title}</h2>
        <span style={{ marginLeft: 'auto', background: 'var(--primary)', color: '#fff', padding: '1px 8px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600 }}>
          {items.length}
        </span>
      </div>

      <form onSubmit={onSubmit} style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '1rem' }}>
        {formFields}
        <button type="submit" disabled={saving} className="btn-primary" style={{ padding: '0.5rem 1rem', fontSize: '0.85rem', display: 'flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}>
          {saving ? '...' : editId ? <><Edit size={13} /> Actualizar</> : <><Plus size={13} /> Agregar</>}
        </button>
        {editId && (
          <button type="button" onClick={onCancel} className="btn-secondary" style={{ padding: '0.5rem 0.75rem', fontSize: '0.85rem' }}>
            <X size={13} />
          </button>
        )}
      </form>

      {msg && (
        <div className={`alert ${msg.includes('Error') || msg.includes('error') ? 'alert-error' : 'alert-success'}`} style={{ marginBottom: '0.75rem', fontSize: '0.83rem' }}>
          {msg}
        </div>
      )}

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
        {items.length === 0 ? (
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>No hay registros todavía.</p>
        ) : items.map(item => renderItem(item))}
      </div>
    </div>
  )
}

export default function AdminCategoriesPage() {
  const [categories, setCategories] = useState([])
  const [brands, setBrands] = useState([])
  const [loadingCat, setLoadingCat] = useState(true)
  const [loadingBrand, setLoadingBrand] = useState(true)

  const [catForm, setCatForm] = useState({ name: '' })
  const [catEditId, setCatEditId] = useState(null)
  const [catSaving, setCatSaving] = useState(false)
  const [catMsg, setCatMsg] = useState('')

  const [brandForm, setBrandForm] = useState({ name: '', category_id: '' })
  const [brandEditId, setBrandEditId] = useState(null)
  const [brandSaving, setBrandSaving] = useState(false)
  const [brandMsg, setBrandMsg] = useState('')

  const [confirmDel, setConfirmDel] = useState(null)
  const [deleting, setDeleting] = useState(false)
  const [delError, setDelError] = useState('')

  const fetchCategories = () => {
    setLoadingCat(true)
    api.get('/categories').then(r => setCategories(r.data)).finally(() => setLoadingCat(false))
  }
  const fetchBrands = () => {
    setLoadingBrand(true)
    api.get('/brands').then(r => setBrands(r.data)).finally(() => setLoadingBrand(false))
  }

  useEffect(() => { fetchCategories(); fetchBrands() }, [])

  const handleCatSubmit = async (e) => {
    e.preventDefault()
    setCatSaving(true); setCatMsg('')
    try {
      if (catEditId) {
        await api.put(`/categories/${catEditId}`, catForm)
        setCatMsg('Categoría actualizada')
        setCatEditId(null)
      } else {
        await api.post('/categories', catForm)
        setCatMsg('Categoría creada')
      }
      setCatForm({ name: '' })
      fetchCategories()
    } catch (e) {
      setCatMsg(e.response?.data?.detail || 'Error al guardar')
    } finally {
      setCatSaving(false)
    }
  }

  const handleBrandSubmit = async (e) => {
    e.preventDefault()
    setBrandSaving(true); setBrandMsg('')
    try {
      const payload = {
        name: brandForm.name,
        category_id: brandForm.category_id ? parseInt(brandForm.category_id) : null,
      }
      if (brandEditId) {
        await api.put(`/brands/${brandEditId}`, payload)
        setBrandMsg('Marca actualizada')
        setBrandEditId(null)
      } else {
        await api.post('/brands', payload)
        setBrandMsg('Marca creada')
      }
      setBrandForm({ name: '', category_id: '' })
      fetchBrands()
    } catch (e) {
      setBrandMsg(e.response?.data?.detail || 'Error al guardar')
    } finally {
      setBrandSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!confirmDel) return
    setDeleting(true); setDelError('')
    try {
      if (confirmDel.type === 'category') {
        await api.delete(`/categories/${confirmDel.id}`)
        fetchCategories()
      } else {
        await api.delete(`/brands/${confirmDel.id}`)
        fetchBrands()
      }
      setConfirmDel(null)
    } catch (e) {
      setDelError(e.response?.data?.detail || 'Error al eliminar')
    } finally {
      setDeleting(false)
    }
  }

  const startEditCat = (cat) => {
    setCatEditId(cat.id)
    setCatForm({ name: cat.name })
    setCatMsg('')
  }
  const startEditBrand = (brand) => {
    setBrandEditId(brand.id)
    setBrandForm({ name: brand.name, category_id: brand.category_id ? String(brand.category_id) : '' })
    setBrandMsg('')
  }

  const chipStyle = (isEdit) => ({
    display: 'inline-flex', alignItems: 'center', gap: '6px',
    padding: '4px 10px', borderRadius: '20px',
    background: isEdit ? 'rgba(255,153,0,0.12)' : '#f3f4f6',
    border: isEdit ? '1px solid var(--primary)' : '1px solid var(--border)',
    fontSize: '0.82rem', fontWeight: 500,
  })

  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 64px)' }}>
      <AdminSidebar />
      <main style={{ flex: 1, padding: '2rem', overflow: 'auto' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.25rem' }}>Categorías y Marcas</h1>
        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
          Administra las categorías y marcas del catálogo.
        </p>

        {loadingCat || loadingBrand ? <div className="spinner" /> : (
          <>
            <CrudSection
              title="Categorías"
              icon={Layers}
              items={categories}
              editId={catEditId}
              saving={catSaving}
              msg={catMsg}
              onSubmit={handleCatSubmit}
              onCancel={() => { setCatEditId(null); setCatForm({ name: '' }); setCatMsg('') }}
              formFields={
                <input
                  value={catForm.name}
                  onChange={e => setCatForm({ name: e.target.value })}
                  placeholder="Nombre de la categoría"
                  required
                  style={{ flex: 1, minWidth: '180px', padding: '0.5rem 0.75rem', border: '1px solid var(--border)', borderRadius: '6px', fontSize: '0.88rem' }}
                />
              }
              renderItem={(cat) => (
                <div key={cat.id} style={chipStyle(catEditId === cat.id)}>
                  <span>{cat.name}</span>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>#{cat.id}</span>
                  <button onClick={() => startEditCat(cat)} style={{ background: 'none', border: 'none', padding: '2px', cursor: 'pointer', color: 'var(--secondary)', display: 'flex' }}>
                    <Edit size={12} />
                  </button>
                  <button onClick={() => { setConfirmDel({ id: cat.id, name: cat.name, type: 'category' }); setDelError('') }} style={{ background: 'none', border: 'none', padding: '2px', cursor: 'pointer', color: '#ef4444', display: 'flex' }}>
                    <Trash2 size={12} />
                  </button>
                </div>
              )}
            />

            <CrudSection
              title="Marcas"
              icon={Tag}
              items={brands}
              editId={brandEditId}
              saving={brandSaving}
              msg={brandMsg}
              onSubmit={handleBrandSubmit}
              onCancel={() => { setBrandEditId(null); setBrandForm({ name: '', category_id: '' }); setBrandMsg('') }}
              formFields={
                <>
                  <input
                    value={brandForm.name}
                    onChange={e => setBrandForm(f => ({ ...f, name: e.target.value }))}
                    placeholder="Nombre de la marca"
                    required
                    style={{ flex: 1, minWidth: '180px', padding: '0.5rem 0.75rem', border: '1px solid var(--border)', borderRadius: '6px', fontSize: '0.88rem' }}
                  />
                  <select
                    value={brandForm.category_id}
                    onChange={e => setBrandForm(f => ({ ...f, category_id: e.target.value }))}
                    style={{ padding: '0.5rem 0.75rem', border: '1px solid var(--border)', borderRadius: '6px', fontSize: '0.88rem' }}
                  >
                    <option value="">Sin categoría</option>
                    {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </>
              }
              renderItem={(brand) => {
                const cat = categories.find(c => c.id === brand.category_id)
                return (
                  <div key={brand.id} style={chipStyle(brandEditId === brand.id)}>
                    <span>{brand.name}</span>
                    {cat && <span style={{ fontSize: '0.7rem', color: 'var(--primary)', fontWeight: 600 }}>{cat.name}</span>}
                    <button onClick={() => startEditBrand(brand)} style={{ background: 'none', border: 'none', padding: '2px', cursor: 'pointer', color: 'var(--secondary)', display: 'flex' }}>
                      <Edit size={12} />
                    </button>
                    <button onClick={() => { setConfirmDel({ id: brand.id, name: brand.name, type: 'brand' }); setDelError('') }} style={{ background: 'none', border: 'none', padding: '2px', cursor: 'pointer', color: '#ef4444', display: 'flex' }}>
                      <Trash2 size={12} />
                    </button>
                  </div>
                )
              }}
            />
          </>
        )}
      </main>

      {confirmDel && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="card" style={{ width: '100%', maxWidth: '400px', padding: '1.75rem', margin: '1rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
              <div style={{ background: '#fee2e2', borderRadius: '50%', padding: '8px', display: 'flex' }}>
                <Trash2 size={18} color="#ef4444" />
              </div>
              <h3 style={{ fontWeight: 700, fontSize: '1rem' }}>
                Eliminar {confirmDel.type === 'category' ? 'categoría' : 'marca'}
              </h3>
            </div>
            <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>
              ¿Eliminar permanentemente <strong>"{confirmDel.name}"</strong>?
            </p>
            <p style={{ fontSize: '0.8rem', background: '#fef9c3', padding: '0.5rem 0.75rem', borderRadius: '6px', border: '1px solid #fde047', marginBottom: '1rem' }}>
              Solo se puede eliminar si no hay productos asociados.
            </p>
            {delError && <div className="alert alert-error" style={{ marginBottom: '1rem', fontSize: '0.83rem' }}>{delError}</div>}
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button onClick={() => { setConfirmDel(null); setDelError('') }} disabled={deleting} className="btn-secondary" style={{ padding: '0.6rem 1.2rem' }}>
                Cancelar
              </button>
              <button onClick={handleDelete} disabled={deleting} style={{ padding: '0.6rem 1.2rem', background: '#ef4444', color: '#fff', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: deleting ? 'default' : 'pointer', opacity: deleting ? 0.7 : 1 }}>
                {deleting ? 'Eliminando...' : 'Eliminar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

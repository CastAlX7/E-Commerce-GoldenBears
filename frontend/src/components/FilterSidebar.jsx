import { useState, useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import api from '../api/client'

export default function FilterSidebar() {
  const [categories, setCategories] = useState([])
  const [brands, setBrands] = useState([])
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const selectedCat = searchParams.get('category_id')
  const selectedBrand = searchParams.get('brand_id')

  useEffect(() => {
    api.get('/categories').then(r => setCategories(r.data)).catch(() => {})
    api.get('/brands').then(r => setBrands(r.data)).catch(() => {})
  }, [])

  const setFilter = (key, value) => {
    const params = new URLSearchParams(searchParams)
    if (value) params.set(key, value)
    else params.delete(key)
    params.delete('page')
    if (key === 'category_id') params.delete('brand_id')
    navigate(`/?${params.toString()}`)
  }

  const clearAll = () => navigate('/')

  const visibleBrands = selectedCat
    ? brands.filter(b => String(b.category_id) === selectedCat)
    : brands

  return (
    <aside style={{ width: '220px', flexShrink: 0 }}>
      <div className="card" style={{ padding: '1rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h3 style={{ fontWeight: 700, fontSize: '0.95rem' }}>Filtros</h3>
          {(selectedCat || selectedBrand) && (
            <button onClick={clearAll} style={{ fontSize: '0.78rem', color: 'var(--primary)', background: 'none', fontWeight: 600 }}>
              Limpiar
            </button>
          )}
        </div>

        <div style={{ marginBottom: '1.2rem' }}>
          <h4 style={{ fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)', marginBottom: '0.6rem' }}>
            Categorías
          </h4>
          {[{ id: null, name: 'Todos' }, ...categories].map(cat => (
            <button
              key={cat.id ?? 'all'}
              onClick={() => setFilter('category_id', cat.id)}
              style={{
                display: 'block', width: '100%', textAlign: 'left', padding: '0.4rem 0.6rem',
                borderRadius: '6px', fontSize: '0.88rem', background: 'none',
                color: String(selectedCat) === String(cat.id) ? 'var(--primary)' : 'var(--text-dark)',
                fontWeight: String(selectedCat) === String(cat.id) ? 700 : 400,
                backgroundColor: String(selectedCat) === String(cat.id) ? '#fff7ed' : 'transparent',
                marginBottom: '2px',
              }}
            >
              {cat.name}
            </button>
          ))}
        </div>

        {visibleBrands.length > 0 && (
          <div>
            <h4 style={{ fontSize: '0.8rem', fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-muted)', marginBottom: '0.6rem' }}>
              Marcas
            </h4>
            {[{ id: null, name: 'Todas' }, ...visibleBrands].map(brand => (
              <button
                key={brand.id ?? 'all'}
                onClick={() => setFilter('brand_id', brand.id)}
                style={{
                  display: 'block', width: '100%', textAlign: 'left', padding: '0.4rem 0.6rem',
                  borderRadius: '6px', fontSize: '0.88rem', background: 'none',
                  color: String(selectedBrand) === String(brand.id) ? 'var(--primary)' : 'var(--text-dark)',
                  fontWeight: String(selectedBrand) === String(brand.id) ? 700 : 400,
                  backgroundColor: String(selectedBrand) === String(brand.id) ? '#fff7ed' : 'transparent',
                  marginBottom: '2px',
                }}
              >
                {brand.name}
              </button>
            ))}
          </div>
        )}
      </div>
    </aside>
  )
}

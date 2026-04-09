import { useState, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import api from '../api/client'
import ProductCard from '../components/ProductCard'
import FilterSidebar from '../components/FilterSidebar'

export default function HomePage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  const page = parseInt(searchParams.get('page') || '1')
  const search = searchParams.get('search') || ''
  const category_id = searchParams.get('category_id') || ''
  const brand_id = searchParams.get('brand_id') || ''

  useEffect(() => {
    setLoading(true)
    const params = { page, size: 12 }
    if (search) params.search = search
    if (category_id) params.category_id = category_id
    if (brand_id) params.brand_id = brand_id

    api.get('/products', { params })
      .then(r => setData(r.data))
      .catch(() => setData(null))
      .finally(() => setLoading(false))
  }, [page, search, category_id, brand_id])

  const setPage = (p) => {
    const params = new URLSearchParams(searchParams)
    params.set('page', p)
    setSearchParams(params)
    window.scrollTo(0, 0)
  }

  return (
    <div className="page-wrapper">
      <div className="container" style={{ display: 'flex', gap: '1.5rem', alignItems: 'flex-start' }}>
        <FilterSidebar />

        <div style={{ flex: 1 }}>
          {search && (
            <div style={{ marginBottom: '1rem' }}>
              <h2 style={{ fontSize: '1.1rem', fontWeight: 600 }}>
                Resultados para: <span style={{ color: 'var(--primary)' }}>{search}</span>
              </h2>
            </div>
          )}

          {loading ? (
            <div className="spinner" />
          ) : !data || data.items.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>
              <p style={{ fontSize: '1.1rem' }}>No se encontraron productos.</p>
            </div>
          ) : (
            <>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
                {data.total} producto{data.total !== 1 ? 's' : ''} encontrado{data.total !== 1 ? 's' : ''}
              </p>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
                {data.items.map(p => <ProductCard key={p.id} product={p} />)}
              </div>

              {data.pages > 1 && (
                <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem', alignItems: 'center' }}>
                  <button
                    onClick={() => setPage(page - 1)}
                    disabled={page <= 1}
                    className="btn-outline"
                    style={{ padding: '0.4rem 0.7rem', opacity: page <= 1 ? 0.4 : 1 }}
                  >
                    <ChevronLeft size={16} />
                  </button>
                  {Array.from({ length: data.pages }, (_, i) => i + 1).map(p => (
                    <button
                      key={p}
                      onClick={() => setPage(p)}
                      style={{
                        width: '36px', height: '36px', borderRadius: '6px', fontWeight: 600, fontSize: '0.9rem',
                        background: p === page ? 'var(--primary)' : '#fff',
                        color: p === page ? '#fff' : 'var(--text-dark)',
                        border: `1.5px solid ${p === page ? 'var(--primary)' : 'var(--border)'}`,
                      }}
                    >
                      {p}
                    </button>
                  ))}
                  <button
                    onClick={() => setPage(page + 1)}
                    disabled={page >= data.pages}
                    className="btn-outline"
                    style={{ padding: '0.4rem 0.7rem', opacity: page >= data.pages ? 0.4 : 1 }}
                  >
                    <ChevronRight size={16} />
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}

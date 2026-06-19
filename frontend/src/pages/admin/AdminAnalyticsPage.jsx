import { useState, useEffect } from 'react'
import { TrendingUp, Package, Tag } from 'lucide-react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

export default function AdminAnalyticsPage() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/admin/analytics')
      .then(r => setData(r.data))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 64px)' }}>
      <AdminSidebar />
      <main style={{ flex: 1, padding: '2rem', overflow: 'auto' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.25rem' }}>Analítica</h1>
        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>
          Rendimiento de ventas y productos.
        </p>

        {loading ? <div className="spinner" /> : data && (
          <>
            {/* KPIs */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
              {[
                { label: 'Ingresos Totales', value: `S/ ${parseFloat(data.total_revenue).toFixed(2)}`, color: '#10b981' },
                { label: 'Pedidos Pagados', value: data.total_orders, color: '#3b82f6' },
                { label: 'Ticket Promedio', value: `S/ ${parseFloat(data.average_ticket).toFixed(2)}`, color: '#f59e0b' },
              ].map(({ label, value, color }) => (
                <div key={label} className="card" style={{ padding: '1.25rem', textAlign: 'center' }}>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '4px' }}>{label}</p>
                  <p style={{ fontSize: '1.6rem', fontWeight: 800, color }}>{value}</p>
                </div>
              ))}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
              {/* Top productos */}
              <div className="card">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '1rem 1.25rem', borderBottom: '1px solid var(--border)' }}>
                  <Package size={16} color="var(--primary)" />
                  <h2 style={{ fontWeight: 700, fontSize: '1rem' }}>Top 5 Productos</h2>
                </div>
                <div style={{ padding: '0.5rem 0' }}>
                  {data.top_products.length === 0 ? (
                    <p style={{ padding: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>Sin datos aún.</p>
                  ) : data.top_products.map((p, i) => (
                    <div key={p.product_id} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.65rem 1.25rem', borderBottom: i < data.top_products.length - 1 ? '1px solid var(--border)' : 'none' }}>
                      <span style={{ fontWeight: 800, fontSize: '1.1rem', color: 'var(--text-muted)', width: '20px' }}>#{i + 1}</span>
                      <img
                        src={p.image_url || 'https://via.placeholder.com/36'}
                        alt={p.name}
                        style={{ width: '36px', height: '36px', objectFit: 'cover', borderRadius: '6px' }}
                        onError={e => { e.target.src = 'https://via.placeholder.com/36' }}
                      />
                      <div style={{ flex: 1 }}>
                        <p style={{ fontWeight: 600, fontSize: '0.85rem' }}>{p.name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{p.units_sold} unidades</p>
                      </div>
                      <span style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--primary)' }}>
                        S/ {parseFloat(p.revenue).toFixed(2)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Ventas por categoría */}
              <div className="card">
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '1rem 1.25rem', borderBottom: '1px solid var(--border)' }}>
                  <Tag size={16} color="var(--primary)" />
                  <h2 style={{ fontWeight: 700, fontSize: '1rem' }}>Ventas por Categoría</h2>
                </div>
                <div style={{ padding: '0.5rem 0' }}>
                  {data.sales_by_category.length === 0 ? (
                    <p style={{ padding: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>Sin datos aún.</p>
                  ) : data.sales_by_category.map((cat, i) => {
                    const maxRevenue = Math.max(...data.sales_by_category.map(c => parseFloat(c.revenue)))
                    const pct = maxRevenue > 0 ? (parseFloat(cat.revenue) / maxRevenue) * 100 : 0
                    return (
                      <div key={cat.category} style={{ padding: '0.65rem 1.25rem', borderBottom: i < data.sales_by_category.length - 1 ? '1px solid var(--border)' : 'none' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                          <span style={{ fontWeight: 600, fontSize: '0.85rem' }}>{cat.category}</span>
                          <span style={{ fontSize: '0.85rem', color: 'var(--primary)', fontWeight: 700 }}>S/ {parseFloat(cat.revenue).toFixed(2)}</span>
                        </div>
                        <div style={{ background: '#f3f4f6', borderRadius: '4px', height: '6px' }}>
                          <div style={{ background: 'var(--primary)', borderRadius: '4px', height: '6px', width: `${pct}%`, transition: 'width 0.3s' }} />
                        </div>
                        <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: '2px' }}>{cat.units_sold} unidades</p>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  )
}

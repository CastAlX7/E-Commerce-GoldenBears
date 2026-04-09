import { useState, useEffect } from 'react'
import { ShoppingBag, Users, Package, TrendingUp, AlertTriangle, DollarSign } from 'lucide-react'
import AdminSidebar from '../../components/AdminSidebar'
import api from '../../api/client'

export default function AdminDashboardPage() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/admin/dashboard')
      .then(r => setStats(r.data))
      .finally(() => setLoading(false))
  }, [])

  const cards = stats ? [
    { label: 'Total Pedidos', value: stats.total_orders, icon: ShoppingBag, color: '#3b82f6' },
    { label: 'Ingresos Totales', value: `S/ ${parseFloat(stats.total_revenue).toFixed(2)}`, icon: DollarSign, color: '#10b981' },
    { label: 'Clientes', value: stats.total_customers, icon: Users, color: '#8b5cf6' },
    { label: 'Productos Activos', value: stats.total_products, icon: Package, color: '#f59e0b' },
    { label: 'Pedidos Hoy', value: stats.orders_today, icon: TrendingUp, color: '#06b6d4' },
    { label: 'Ingresos Hoy', value: `S/ ${parseFloat(stats.revenue_today).toFixed(2)}`, icon: DollarSign, color: '#ec4899' },
  ] : []

  return (
    <div style={{ display: 'flex', minHeight: 'calc(100vh - 64px)' }}>
      <AdminSidebar />
      <main style={{ flex: 1, padding: '2rem', overflow: 'auto' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.25rem' }}>Dashboard</h1>
        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem', fontSize: '0.9rem' }}>Resumen general del negocio.</p>

        {loading ? <div className="spinner" /> : (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
              {cards.map(({ label, value, icon: Icon, color }) => (
                <div key={label} className="card" style={{ padding: '1.25rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ background: color + '20', borderRadius: '10px', padding: '0.75rem', display: 'flex' }}>
                    <Icon size={22} color={color} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginBottom: '2px' }}>{label}</p>
                    <p style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-dark)' }}>{value}</p>
                  </div>
                </div>
              ))}
            </div>

            {stats.low_stock_count > 0 && (
              <div className="alert alert-warning" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <AlertTriangle size={16} />
                <strong>{stats.low_stock_count} producto(s)</strong> con stock bajo (≤10 unidades). Revisa el inventario.
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}

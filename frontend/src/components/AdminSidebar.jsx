import { NavLink } from 'react-router-dom'
import { LayoutDashboard, Package, ShoppingBag, Users, BarChart2, Layers } from 'lucide-react'

const NAV_ITEMS = [
  { label: 'Dashboard', icon: LayoutDashboard, to: '/admin' },
  { label: 'Inventario', icon: Package, to: '/admin/inventory' },
  { label: 'Categorías', icon: Layers, to: '/admin/categories' },
  { label: 'Pedidos', icon: ShoppingBag, to: '/admin/orders' },
  { label: 'Clientes', icon: Users, to: '/admin/clients' },
  { label: 'Analítica', icon: BarChart2, to: '/admin/analytics' },
]

export default function AdminSidebar() {
  return (
    <aside style={{ width: '200px', background: 'var(--dark-navy)', padding: '1.5rem 0', flexShrink: 0 }}>
      <div style={{ padding: '0 1rem', marginBottom: '1.5rem' }}>
        <p style={{ color: '#9ca3af', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.1em' }}>Admin Panel</p>
        <p style={{ color: '#6b7280', fontSize: '0.72rem' }}>Management Console</p>
      </div>
      {NAV_ITEMS.map(({ label, icon: Icon, to }) => (
        <NavLink
          key={to}
          to={to}
          end={to === '/admin'}
          style={({ isActive }) => ({
            display: 'flex', alignItems: 'center', gap: '10px', padding: '0.65rem 1rem',
            color: isActive ? 'var(--primary)' : '#9ca3af',
            background: isActive ? 'rgba(255,153,0,0.1)' : 'transparent',
            borderLeft: isActive ? '3px solid var(--primary)' : '3px solid transparent',
            fontSize: '0.9rem', fontWeight: isActive ? 600 : 400,
            textDecoration: 'none',
          })}
        >
          <Icon size={16} /> {label}
        </NavLink>
      ))}
      <div style={{ padding: '1rem', marginTop: '2rem', borderTop: '1px solid rgba(255,255,255,0.1)' }}>
        <NavLink to="/" style={{ color: '#9ca3af', fontSize: '0.8rem', textDecoration: 'none' }}>← Volver a la tienda</NavLink>
      </div>
    </aside>
  )
}

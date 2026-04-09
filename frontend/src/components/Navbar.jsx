import { useState, useRef, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ShoppingCart, Search, User, ChevronDown, LogOut, Package, LayoutDashboard } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import { useCart } from '../contexts/CartContext'
import api from '../api/client'

export default function Navbar() {
  const { user, logout } = useAuth()
  const { cartCount } = useCart()
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [categories, setCategories] = useState([])
  const [showCats, setShowCats] = useState(false)
  const [showUser, setShowUser] = useState(false)
  const catsRef = useRef(null)
  const userRef = useRef(null)

  useEffect(() => {
    api.get('/categories').then(r => setCategories(r.data)).catch(() => {})
  }, [])

  useEffect(() => {
    function handler(e) {
      if (catsRef.current && !catsRef.current.contains(e.target)) setShowCats(false)
      if (userRef.current && !userRef.current.contains(e.target)) setShowUser(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const handleSearch = (e) => {
    e.preventDefault()
    if (search.trim()) navigate(`/?search=${encodeURIComponent(search.trim())}`)
  }

  const handleLogout = async () => {
    await logout()
    navigate('/')
  }

  return (
    <nav style={{
      background: 'var(--dark-navy)',
      color: '#fff',
      position: 'sticky',
      top: 0,
      zIndex: 100,
      boxShadow: '0 2px 8px rgba(0,0,0,0.3)',
    }}>
      <div className="container" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', height: '64px' }}>
        {/* Logo */}
        <Link to="/" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexShrink: 0 }}>
          <span style={{ fontSize: '1.3rem', fontWeight: 800, color: 'var(--primary)', letterSpacing: '-0.02em' }}>
            GOLDEN<span style={{ color: '#fff' }}>BEARS</span>
          </span>
        </Link>

        {/* Categories dropdown */}
        <div ref={catsRef} style={{ position: 'relative' }}>
          <button
            onClick={() => setShowCats(p => !p)}
            style={{ display: 'flex', alignItems: 'center', gap: '4px', background: 'none', color: '#fff', fontSize: '0.9rem', padding: '0.4rem 0.6rem', borderRadius: '6px' }}
          >
            Categorías <ChevronDown size={14} />
          </button>
          {showCats && (
            <div style={{ position: 'absolute', top: '110%', left: 0, background: '#fff', borderRadius: '8px', boxShadow: '0 4px 20px rgba(0,0,0,0.15)', minWidth: '180px', padding: '0.5rem 0', zIndex: 200 }}>
              <Link to="/" onClick={() => setShowCats(false)} style={{ display: 'block', padding: '0.5rem 1rem', color: 'var(--text-dark)', fontSize: '0.9rem' }}>
                Todos los productos
              </Link>
              {categories.map(cat => (
                <Link
                  key={cat.id}
                  to={`/?category_id=${cat.id}`}
                  onClick={() => setShowCats(false)}
                  style={{ display: 'block', padding: '0.5rem 1rem', color: 'var(--text-dark)', fontSize: '0.9rem' }}
                >
                  {cat.name}
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Search bar */}
        <form onSubmit={handleSearch} style={{ flex: 1, display: 'flex' }}>
          <div style={{ display: 'flex', width: '100%', background: '#fff', borderRadius: '6px', overflow: 'hidden' }}>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Buscar productos..."
              style={{ flex: 1, padding: '0.5rem 0.85rem', border: 'none', outline: 'none', fontSize: '0.9rem', color: 'var(--text-dark)' }}
            />
            <button type="submit" style={{ padding: '0 0.85rem', background: 'var(--primary)', color: '#fff', display: 'flex', alignItems: 'center' }}>
              <Search size={16} />
            </button>
          </div>
        </form>

        {/* Nav links */}
        {user && (
          <Link to="/orders" style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#ccc', fontSize: '0.9rem', whiteSpace: 'nowrap' }}>
            <Package size={16} /> Pedidos
          </Link>
        )}

        {/* Cart */}
        <Link to="/cart" style={{ position: 'relative', color: '#fff', display: 'flex', alignItems: 'center' }}>
          <ShoppingCart size={22} />
          {cartCount > 0 && (
            <span className="badge" style={{ position: 'absolute', top: '-8px', right: '-8px', fontSize: '0.65rem' }}>
              {cartCount}
            </span>
          )}
        </Link>

        {/* User */}
        {user ? (
          <div ref={userRef} style={{ position: 'relative' }}>
            <button
              onClick={() => setShowUser(p => !p)}
              style={{ background: 'var(--primary)', borderRadius: '50%', width: '34px', height: '34px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}
            >
              <User size={16} />
            </button>
            {showUser && (
              <div style={{ position: 'absolute', top: '110%', right: 0, background: '#fff', borderRadius: '8px', boxShadow: '0 4px 20px rgba(0,0,0,0.15)', minWidth: '180px', padding: '0.5rem 0', zIndex: 200 }}>
                <div style={{ padding: '0.5rem 1rem', fontSize: '0.8rem', color: 'var(--text-muted)', borderBottom: '1px solid var(--border)' }}>
                  {user.email}
                </div>
                {user.role === 'admin' && (
                  <Link to="/admin" onClick={() => setShowUser(false)} style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '0.5rem 1rem', color: 'var(--text-dark)', fontSize: '0.9rem' }}>
                    <LayoutDashboard size={14} /> Admin Panel
                  </Link>
                )}
                <button onClick={handleLogout} style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '0.5rem 1rem', color: 'var(--error)', fontSize: '0.9rem', width: '100%', background: 'none', textAlign: 'left' }}>
                  <LogOut size={14} /> Cerrar sesión
                </button>
              </div>
            )}
          </div>
        ) : (
          <Link to="/login" className="btn-primary" style={{ whiteSpace: 'nowrap', padding: '0.4rem 1rem' }}>
            Ingresar
          </Link>
        )}
      </div>
    </nav>
  )
}

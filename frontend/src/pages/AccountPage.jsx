import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Trash2, User } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import api from '../api/client'

export default function AccountPage() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  const handleDelete = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      await api.delete('/auth/me', { data: { email } })
      await logout()
      navigate('/')
    } catch (err) {
      setError(err.response?.data?.detail || 'Error al eliminar la cuenta')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="container" style={{ maxWidth: '520px', padding: '3rem 1rem' }}>
      {/* Info de cuenta */}
      <div className="card" style={{ padding: '1.5rem', marginBottom: '1.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
          <div style={{ background: 'var(--primary)', borderRadius: '50%', width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <User size={20} color="#fff" />
          </div>
          <div>
            <p style={{ fontWeight: 700, fontSize: '0.95rem' }}>{user?.email}</p>
            <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', textTransform: 'capitalize' }}>{user?.role}</p>
          </div>
        </div>
      </div>

      {/* Zona de peligro */}
      <div className="card" style={{ padding: '1.5rem', border: '1px solid #fca5a5' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '0.5rem' }}>
          <Trash2 size={18} color="#ef4444" />
          <h2 style={{ fontWeight: 700, fontSize: '1rem', color: '#ef4444' }}>Eliminar cuenta</h2>
        </div>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '1.25rem' }}>
          Esta acción es permanente e irreversible. Se eliminarán todos tus datos. No es posible si tienes pedidos registrados.
        </p>

        {!showConfirm ? (
          <button
            onClick={() => setShowConfirm(true)}
            style={{ padding: '0.6rem 1.2rem', background: '#fee2e2', color: '#ef4444', border: '1px solid #fca5a5', borderRadius: '6px', fontWeight: 600, cursor: 'pointer', fontSize: '0.88rem' }}
          >
            Quiero eliminar mi cuenta
          </button>
        ) : (
          <form onSubmit={handleDelete}>
            <div className="form-group">
              <label style={{ fontSize: '0.85rem' }}>
                Escribe tu correo <strong>{user?.email}</strong> para confirmar:
              </label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder={user?.email}
                required
                autoFocus
              />
            </div>
            {error && <div className="alert alert-error" style={{ marginBottom: '1rem', fontSize: '0.85rem' }}>{error}</div>}
            <div style={{ display: 'flex', gap: '0.75rem' }}>
              <button
                type="button"
                onClick={() => { setShowConfirm(false); setEmail(''); setError('') }}
                className="btn-secondary"
                style={{ padding: '0.6rem 1.2rem' }}
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={loading}
                style={{ padding: '0.6rem 1.2rem', background: '#ef4444', color: '#fff', border: 'none', borderRadius: '6px', fontWeight: 600, cursor: loading ? 'default' : 'pointer', opacity: loading ? 0.7 : 1 }}
              >
                {loading ? 'Eliminando...' : 'Eliminar mi cuenta'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  )
}

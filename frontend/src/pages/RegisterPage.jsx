import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export default function RegisterPage() {
  const { register } = useAuth()
  const navigate = useNavigate()
  const [form, setForm] = useState({ email: '', password: '', full_name: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handle = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await register(form.email, form.password, form.full_name)
      navigate('/')
    } catch (err) {
      setError(err.response?.data?.detail || 'Error al registrarse')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="page-wrapper" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div className="card" style={{ width: '100%', maxWidth: '420px', padding: '2rem' }}>
        <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--dark-navy)' }}>
            GOLDEN<span style={{ color: 'var(--primary)' }}>BEARS</span>
          </h1>
          <p style={{ color: 'var(--text-muted)', marginTop: '0.3rem' }}>Crea tu cuenta</p>
        </div>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={handle}>
          <div className="form-group">
            <label>Nombre completo</label>
            <input type="text" value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))} placeholder="Juan Pérez" />
          </div>
          <div className="form-group">
            <label>Email</label>
            <input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} required placeholder="tu@email.com" />
          </div>
          <div className="form-group">
            <label>Contraseña</label>
            <input type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} required placeholder="Mínimo 8 caracteres" minLength={6} />
          </div>
          <button type="submit" className="btn-primary" disabled={loading} style={{ width: '100%', padding: '0.75rem', fontSize: '1rem', marginTop: '0.5rem' }}>
            {loading ? 'Registrando...' : 'Crear cuenta'}
          </button>
        </form>
        <p style={{ textAlign: 'center', marginTop: '1rem', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
          ¿Ya tienes cuenta? <Link to="/login" style={{ color: 'var(--primary)', fontWeight: 600 }}>Inicia sesión</Link>
        </p>
      </div>
    </div>
  )
}

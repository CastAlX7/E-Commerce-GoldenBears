export default function StarRating({ rating, count }) {
  const stars = Array.from({ length: 5 }, (_, i) => i + 1)
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
      {stars.map((s) => (
        <span key={s} className={s <= Math.round(rating) ? 'star' : 'star empty'} style={{ fontSize: '0.85rem' }}>★</span>
      ))}
      {count !== undefined && (
        <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginLeft: '2px' }}>({count})</span>
      )}
    </div>
  )
}

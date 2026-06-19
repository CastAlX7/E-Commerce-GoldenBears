import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import api from '../api/client'
import { useAuth } from './AuthContext'

const CartContext = createContext(null)

export function CartProvider({ children }) {
  const { user } = useAuth()
  const [cart, setCart] = useState({ items: [], subtotal: 0 })
  const [cartCount, setCartCount] = useState(0)

  const fetchCart = useCallback(async () => {
    if (!user) { setCart({ items: [], subtotal: 0 }); setCartCount(0); return }
    try {
      const { data } = await api.get('/cart')
      setCart(data)
      setCartCount(data.items.reduce((sum, i) => sum + i.quantity, 0))
    } catch {
      setCart({ items: [], subtotal: 0 })
      setCartCount(0)
    }
  }, [user])

  useEffect(() => { fetchCart() }, [fetchCart])

  const addToCart = async (productId, quantity = 1) => {
    await api.post('/cart/items', { product_id: productId, quantity })
    await fetchCart()
  }

  const updateItem = async (productId, quantity) => {
    if (quantity <= 0) {
      await removeItem(productId)
      return
    }
    await api.put(`/cart/items/${productId}`, { quantity })
    await fetchCart()
  }

  const removeItem = async (productId) => {
    await api.delete(`/cart/items/${productId}`)
    await fetchCart()
  }

  const clearCart = async () => {
    await api.delete('/cart')
    await fetchCart()
  }

  return (
    <CartContext.Provider value={{ cart, cartCount, fetchCart, addToCart, updateItem, removeItem, clearCart }}>
      {children}
    </CartContext.Provider>
  )
}

export function useCart() {
  return useContext(CartContext)
}

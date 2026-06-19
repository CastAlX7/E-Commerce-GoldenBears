import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import { CartProvider } from './contexts/CartContext'
import Navbar from './components/Navbar'
import ProtectedRoute from './components/ProtectedRoute'

import HomePage from './pages/HomePage'
import ProductDetailPage from './pages/ProductDetailPage'
import CartPage from './pages/CartPage'
import CheckoutPage from './pages/CheckoutPage'
import OrdersPage from './pages/OrdersPage'
import OrderDetailPage from './pages/OrderDetailPage'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import AdminInventoryPage from './pages/admin/AdminInventoryPage'
import AdminDashboardPage from './pages/admin/AdminDashboardPage'
import AdminOrdersPage from './pages/admin/AdminOrdersPage'
import AdminClientsPage from './pages/admin/AdminClientsPage'
import AdminAnalyticsPage from './pages/admin/AdminAnalyticsPage'
import AdminCategoriesPage from './pages/admin/AdminCategoriesPage'
import AccountPage from './pages/AccountPage'

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <CartProvider>
          <Navbar />
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/products/:id" element={<ProductDetailPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/cart" element={<CartPage />} />
            <Route path="/checkout" element={
              <ProtectedRoute><CheckoutPage /></ProtectedRoute>
            } />
            <Route path="/orders" element={
              <ProtectedRoute><OrdersPage /></ProtectedRoute>
            } />
            <Route path="/orders/:id" element={
              <ProtectedRoute><OrderDetailPage /></ProtectedRoute>
            } />
            <Route path="/account" element={
              <ProtectedRoute><AccountPage /></ProtectedRoute>
            } />
            <Route path="/admin" element={
              <ProtectedRoute adminOnly><AdminDashboardPage /></ProtectedRoute>
            } />
            <Route path="/admin/inventory" element={
              <ProtectedRoute adminOnly><AdminInventoryPage /></ProtectedRoute>
            } />
            <Route path="/admin/orders" element={
              <ProtectedRoute adminOnly><AdminOrdersPage /></ProtectedRoute>
            } />
            <Route path="/admin/clients" element={
              <ProtectedRoute adminOnly><AdminClientsPage /></ProtectedRoute>
            } />
            <Route path="/admin/analytics" element={
              <ProtectedRoute adminOnly><AdminAnalyticsPage /></ProtectedRoute>
            } />
            <Route path="/admin/categories" element={
              <ProtectedRoute adminOnly><AdminCategoriesPage /></ProtectedRoute>
            } />
          </Routes>
        </CartProvider>
      </AuthProvider>
    </BrowserRouter>
  )
}

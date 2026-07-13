import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import HTTPException

from app.services.cart_service import add_to_cart, update_cart_item

# Test add_to_cart lanza 404 si el producto no existe
def test_add_to_cart_producto_no_encontrado_lanza_404():
    """
    get_available_stock (llamado internamente por add_to_cart) consulta el
    producto en DB. Si scalar_one_or_none devuelve None.
    get_locked_quantity se parchea para no intentar conectarse a Redis.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None  # producto no existe
        mock_db.execute.return_value = mock_result

        with patch(
            "app.services.cart_service.get_locked_quantity",
            new=AsyncMock(return_value=0),
        ):
            # ACT + ASSERT
            with pytest.raises(HTTPException) as exc_info:
                await add_to_cart(mock_db, "user-id", "product-id-inexistente", 1)

        assert exc_info.value.status_code == 404

    asyncio.run(_run())

# Test add_to_cart lanza 400 si la cantidad supera el stock disponible
def test_add_to_cart_stock_insuficiente_lanza_400():
    """
    Escenario: stock=3, locks=0, sin item previo en carrito.
    El cliente intenta agregar 5 unidades → available=3 < qty=5 → 400.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()

        mock_product = MagicMock()
        mock_product.is_enabled = True
        mock_product.stock = 3  # solo 3 unidades en stock

        mock_result_product = MagicMock()
        mock_result_product.scalar_one_or_none.return_value = mock_product

        mock_result_cart = MagicMock()
        mock_result_cart.scalar_one_or_none.return_value = None  # item nuevo

        mock_db.execute.side_effect = [mock_result_product, mock_result_cart]

        with patch(
            "app.services.cart_service.get_locked_quantity",
            new=AsyncMock(return_value=0),  # 0 unidades bloqueadas por otros usuarios
        ):
            # ACT + ASSERT
            with pytest.raises(HTTPException) as exc_info:
                await add_to_cart(mock_db, "user-id", "product-id", quantity=5)

        assert exc_info.value.status_code == 400
        assert "available" in exc_info.value.detail

    asyncio.run(_run())

# Test update_cart_item lanza 404 si el item no existe en el carrito
def test_update_cart_item_no_encontrado_lanza_404():
    """
    update_cart_item primero verifica stock disponible y luego busca
    el CartItem del usuario. Si el item no existe (producto nunca fue
    agregado al carrito de ese usuario) → 404.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()

        mock_product = MagicMock()
        mock_product.is_enabled = True
        mock_product.stock = 10  # stock suficiente, no falla aquí

        mock_result_product = MagicMock()
        mock_result_product.scalar_one_or_none.return_value = mock_product

        mock_result_cart = MagicMock()
        mock_result_cart.scalar_one_or_none.return_value = None  # item no existe

        mock_db.execute.side_effect = [mock_result_product, mock_result_cart]

        with patch(
            "app.services.cart_service.get_locked_quantity",
            new=AsyncMock(return_value=0),
        ):
            # ACT + ASSERT
            with pytest.raises(HTTPException) as exc_info:
                await update_cart_item(mock_db, "user-id", "product-id", quantity=2)

        assert exc_info.value.status_code == 404
        assert "Cart item not found" in exc_info.value.detail

    asyncio.run(_run())

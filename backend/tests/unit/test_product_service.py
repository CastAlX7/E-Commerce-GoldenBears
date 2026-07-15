import asyncio
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.services.product_service import (
    create_category,
    delete_category,
    get_product,
    hard_delete_product,
)

# Test get_product lanza 404 si el producto no existe
def test_get_product_no_encontrado_lanza_404():
    """
    Si db.execute no devuelve ningún producto para ese UUID,
    get_product debe lanzar HTTPException 404.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None  # producto no existe
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await get_product(mock_db, "uuid-que-no-existe")

        assert exc_info.value.status_code == 404
        assert "Product not found" in exc_info.value.detail

    asyncio.run(_run())

# Test hard_delete_product lanza 409 si el producto tiene pedidos
def test_hard_delete_producto_con_pedidos_lanza_409():
    """
    Si el producto tiene OrderItems asociados, la eliminación física
    está bloqueada (integridad referencial). El service lanza 409
    sugiriendo usar el soft-delete (disable) en su lugar.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_product = MagicMock()

        mock_result_product = MagicMock()
        mock_result_product.scalar_one_or_none.return_value = mock_product

        mock_result_orders = MagicMock()
        mock_result_orders.scalar_one.return_value = 2  # 2 pedidos asociados

        mock_db.execute.side_effect = [mock_result_product, mock_result_orders]

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await hard_delete_product(mock_db, "product-id-con-pedidos")

        assert exc_info.value.status_code == 409

    asyncio.run(_run())

# Test create_category lanza 409 si el slug ya existe
def test_create_category_slug_duplicado_lanza_409():
    """
    _slugify("Electrónica") y _slugify("electronica") producen el mismo slug.
    create_category verifica duplicados por slug antes de insertar.
    Si ya existe, lanza 409 — evita categorías duplicadas en la DB.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        # db.execute devuelve una categoría existente
        mock_result.scalar_one_or_none.return_value = MagicMock()
        mock_db.execute.return_value = mock_result

        data = SimpleNamespace(name="Electrónica")

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await create_category(mock_db, data)

        assert exc_info.value.status_code == 409

    asyncio.run(_run())

# Test delete_category lanza 409 si tiene productos activos
def test_delete_category_con_productos_lanza_409():
    """
    Una categoría que tiene productos asociados no puede eliminarse —
    los productos quedarían sin categoría. El service lanza 409
    con el conteo exacto de productos afectados en el mensaje.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()

        mock_result_cat = MagicMock()
        mock_result_cat.scalar_one_or_none.return_value = MagicMock()  # categoría existe

        mock_result_count = MagicMock()
        mock_result_count.scalar_one.return_value = 5  # 5 productos en la categoría

        mock_db.execute.side_effect = [mock_result_cat, mock_result_count]

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await delete_category(mock_db, category_id=1)

        assert exc_info.value.status_code == 409
        assert "5" in exc_info.value.detail

        mock_db.delete.assert_not_called()

    asyncio.run(_run())

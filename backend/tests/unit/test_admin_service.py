import asyncio
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.services.admin_service import delete_client, update_order_status

# Test update_order_status lanza 404 si la orden no existe
def test_update_order_status_orden_no_encontrada_lanza_404():
    """
    Si db.execute no devuelve ninguna orden para ese ID,
    update_order_status debe lanzar 404 antes de intentar
    cualquier cambio de estado.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None  # orden no existe en DB
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await update_order_status(mock_db, "order-id-inexistente", "shipped")

        assert exc_info.value.status_code == 404
        assert "Pedido no encontrado" in exc_info.value.detail

    asyncio.run(_run())

# Test update_order_status lanza 409 en transición de estado inválida
def test_update_order_status_transicion_invalida_lanza_409():
    """
    "delivered" es un estado terminal. Intentar mover una orden entregada 
    a "shipped" viola las reglas de negocio. 
    """
    async def _run():
        # ARRANGE
        mock_order = MagicMock()
        mock_order.status = "delivered"  # estado final

        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_order
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await update_order_status(mock_db, "order-id", new_status="shipped")

        assert exc_info.value.status_code == 409
        assert "delivered" in exc_info.value.detail

    asyncio.run(_run())

# Test delete_client lanza 409 si el cliente tiene pedidos registrados
def test_delete_client_con_pedidos_lanza_409():
    """
    Un cliente con pedidos no puede eliminarse — sus órdenes son registros
    contables que deben conservarse. El service lanza 409 e indica que
    se puede usar toggle_client_active (suspensión) como alternativa.
    """
    async def _run():
        # ARRANGE
        mock_client = MagicMock()

        mock_result_user = MagicMock()
        mock_result_user.scalar_one_or_none.return_value = mock_client

        mock_result_orders = MagicMock()
        mock_result_orders.scalar_one.return_value = 3  # 3 pedidos 

        mock_db = AsyncMock()
        mock_db.execute.side_effect = [mock_result_user, mock_result_orders]

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await delete_client(mock_db, "user-id-con-pedidos")

        assert exc_info.value.status_code == 409
        assert "pedidos asociados" in exc_info.value.detail

    asyncio.run(_run())

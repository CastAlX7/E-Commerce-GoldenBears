import asyncio
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.services.order_service import (
    charge_culqi,
    confirm_checkout,
    initiate_checkout,
)

# Test charge_culqi retorna autorizado en entorno de test (sin HTTP)
def test_charge_culqi_clave_test_retorna_autorizado():
    """
    Con la CULQI_SECRET_KEY por defecto (empieza con "sk_test_XXX"),
    charge_culqi devuelve un dict hardcodeado sin llamar a httpx.
    Verifica que el entorno de pruebas NUNCA hace llamadas HTTP reales
    al gateway de Culqi — protege contra cargos accidentales.
    """
    async def _run():
        # ARRANGE
        token = "tok_test_abc123"
        amount_cents = 15000  # S/150
        email = "cliente@goldenbearstest.com"

        # ACT
        result = await charge_culqi(token, amount_cents, email)

        # ASSERT
        assert result["id"] == "mock_charge_id"
        assert result["outcome"]["type"] == "authorized"

    asyncio.run(_run())

# Test initiate_checkout lanza 400 si el carrito está vacío
def test_initiate_checkout_carrito_vacio_lanza_400():
    """
    initiate_checkout consulta los CartItems del usuario en DB.
    Si la lista está vacía, debe rechazar el proceso con 400
    antes de calcular costos, bloquear stock o hacer ninguna operación.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = []  # carrito vacío
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await initiate_checkout(mock_db, "user-id", "Lima", "boleta", "card")

        assert exc_info.value.status_code == 400
        assert "Cart is empty" in exc_info.value.detail

    asyncio.run(_run())

# Test confirm_checkout lanza 422 si factura no tiene RUC
def test_confirm_checkout_factura_sin_ruc_lanza_422():
    """
    Una factura electrónica requiere RUC y Razón Social obligatoriamente.
    Si alguno está ausente, confirm_checkout debe lanzar 422 ANTES de
    intentar cobrar ni crear registros en la DB.

    Se simula un carrito con un item válido para superar la 1ª guarda
    (carrito vacío) y llegar a la validación de datos de facturación.
    """
    async def _run():
        # ARRANGE 
        mock_product = MagicMock()
        mock_product.is_enabled = True
        mock_product.stock = 5
        mock_product.price = Decimal("100.00")

        mock_cart_item = MagicMock()
        mock_cart_item.product = mock_product
        mock_cart_item.quantity = 1

        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [mock_cart_item]
        mock_db.execute.return_value = mock_result

        mock_user = MagicMock()
        mock_user.id = "user-id"

        # request de factura sin RUC ni razón social
        mock_data = MagicMock()
        mock_data.receipt_type = "factura"
        mock_data.billing.ruc = None          # sin RUC
        mock_data.billing.razon_social = None  # sin razón social

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await confirm_checkout(mock_db, mock_user, mock_data)

        assert exc_info.value.status_code == 422
        assert "RUC" in exc_info.value.detail

    asyncio.run(_run())

# Test confirm_checkout lanza 400 si el stock real es insuficiente
def test_confirm_checkout_stock_insuficiente_lanza_400():
    """
    confirm_checkout hace una segunda verificación de stock al momento
    de confirmar (doble guarda con initiate_checkout). Si otro usuario
    compró las últimas unidades entre el initiate y el confirm, lanza 400.
    """
    async def _run():
        # ARRANGE — producto con stock insuficiente al momento de confirmar
        mock_product = MagicMock()
        mock_product.is_enabled = True
        mock_product.stock = 1        # solo queda 1 unidad en stock real
        mock_product.name = "AirPods Pro 2"

        mock_cart_item = MagicMock()
        mock_cart_item.product = mock_product
        mock_cart_item.quantity = 3   # el cliente quiere comprar 3

        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [mock_cart_item]
        mock_db.execute.return_value = mock_result

        mock_user = MagicMock()
        mock_user.id = "user-id"

        mock_data = MagicMock()
        mock_data.receipt_type = "boleta"  # boleta no requiere RUC
        mock_data.billing.ruc = None

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await confirm_checkout(mock_db, mock_user, mock_data)

        assert exc_info.value.status_code == 400
        assert "AirPods Pro 2" in exc_info.value.detail

    asyncio.run(_run())

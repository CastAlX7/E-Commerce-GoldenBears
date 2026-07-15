import asyncio
from unittest.mock import MagicMock, patch

import pytest

from app.services.sns_service import publish_order_created

# Test publish retorna False si SNS no está configurado (sin patch)
def test_publish_order_created_sin_sns_configurado_retorna_false():
    """
    Si SNS_TOPIC_ARN está vacío (entorno local o de tests), _sns_client
    queda como None en el módulo. publish_order_created debe retornar
    False inmediatamente — garantiza que el checkout no falla si SNS
    no está disponible en el entorno de desarrollo.
    """
    async def _run():
        # ARRANGE — _sns_client ya es None en test (SNS_TOPIC_ARN="")

        # ACT
        result = await publish_order_created(
            order_id="order-abc-123",
            items=[{"product_id": "p-001", "quantity": 2}],
            total=150.0,
            billing={"dni": "12345678"},
        )

        # ASSERT
        assert result is False

    asyncio.run(_run())

# Test publish retorna False si boto3 lanza una excepción (con patch)
def test_publish_order_created_excepcion_boto3_retorna_false():
    """
    Si AWS falla (timeout, credenciales expiradas, throttling), boto3
    lanzará una excepción dentro de asyncio.to_thread().
    publish_order_created debe capturarla y retornar False — el checkout
    ya se confirmó y el comprobante NO debe fallar por un error de SNS.
    """
    async def _run():
        # ARRANGE
        mock_sns_client = MagicMock()
        mock_sns_client.publish.side_effect = Exception("AWS connection timeout")

        with patch("app.services.sns_service._sns_client", mock_sns_client):
            # ACT
            result = await publish_order_created(
                order_id="order-xyz-456",
                items=[{"product_id": "p-002", "quantity": 1}],
                total=200.0,
                billing={},
            )

        # ASSERT
        assert result is False

    asyncio.run(_run())

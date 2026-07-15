import asyncio
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.services.auth_service import (
    authenticate_user,
    hash_password,
    register_user,
)

# Test register_user rechaza email ya registrado (409 Conflict)
def test_register_user_email_duplicado_lanza_409():
    """
    Si db.execute devuelve un usuario existente para ese email,
    register_user debe lanzar HTTPException 409.
    Verifica la guarda de integridad única de emails.
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = MagicMock(email="ya@existe.com")
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await register_user(mock_db, "ya@existe.com", "password123")

        assert exc_info.value.status_code == 409
        assert "already registered" in exc_info.value.detail

        mock_db.add.assert_not_called()

    asyncio.run(_run())

# Test authenticate_user rechaza usuario inexistente (401)
def test_authenticate_user_usuario_no_existe_lanza_401():
    """
    Si db.execute no encuentra ningún usuario con ese email,
    authenticate_user debe lanzar 401 (no 404 — por seguridad,
    no se revela si el email existe o no en el sistema).
    """
    async def _run():
        # ARRANGE
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None  # usuario no existe
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await authenticate_user(mock_db, "noexiste@test.com", "cualquiera")

        assert exc_info.value.status_code == 401

    asyncio.run(_run())

# Test authenticate_user rechaza contraseña incorrecta (401)
def test_authenticate_user_password_incorrecta_lanza_401():
    """
    El usuario existe en DB pero la contraseña no coincide.
    Se usa hash_password para generar un hash bcrypt
    válido — verify_password se ejecuta con lógica real.
    """
    async def _run():
        # ARRANGE
        mock_user = MagicMock()
        mock_user.hashed_password = hash_password("contraseña_correcta")
        mock_user.is_active = True

        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await authenticate_user(mock_db, "user@test.com", "contraseña_incorrecta")

        assert exc_info.value.status_code == 401

    asyncio.run(_run())

# Test authenticate_user rechaza cuenta suspendida (403)
def test_authenticate_user_cuenta_inactiva_lanza_403():
    """
    Un usuario con is_active=False no puede iniciar sesión aunque
    su contraseña sea correcta. El 403 es semánticamente distinto
    al 401 — las credenciales son válidas pero el acceso está denegado.
    """
    async def _run():
        # ARRANGE
        contraseña = "mi_contraseña_valida"
        mock_user = MagicMock()
        mock_user.hashed_password = hash_password(contraseña)
        mock_user.is_active = False  # cuenta suspendida

        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = mock_user
        mock_db.execute.return_value = mock_result

        # ACT + ASSERT
        with pytest.raises(HTTPException) as exc_info:
            await authenticate_user(mock_db, "user@test.com", contraseña)

        assert exc_info.value.status_code == 403

    asyncio.run(_run())

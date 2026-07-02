import logging

import redis.asyncio as redis

from app.config import settings

logger = logging.getLogger(__name__)

_client: redis.Redis | None = None


def get_redis() -> redis.Redis | None:
    global _client
    if not settings.REDIS_HOST:
        return None
    if _client is None:
        _client = redis.Redis(
            host=settings.REDIS_HOST,
            port=int(settings.REDIS_PORT),
            password=settings.REDIS_AUTH_TOKEN or None,
            ssl=True,
            decode_responses=True,
        )
    return _client


async def cache_get(key: str) -> str | None:
    client = get_redis()
    if not client:
        return None
    try:
        return await client.get(key)
    except Exception:
        logger.exception("Error leyendo cache Redis para la key %s", key)
        return None


async def cache_set(key: str, value: str, ttl: int = 60) -> None:
    client = get_redis()
    if not client:
        return
    try:
        await client.set(key, value, ex=ttl)
    except Exception:
        logger.exception("Error escribiendo cache Redis para la key %s", key)


async def cache_delete(*keys: str) -> None:
    client = get_redis()
    if not client:
        return
    try:
        await client.delete(*keys)
    except Exception:
        logger.exception("Error borrando cache Redis para las keys %s", keys)

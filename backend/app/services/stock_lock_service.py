import json
import uuid

from app.redis_client import get_redis

LOCK_TTL_SECONDS = 15 * 60


async def create_stock_lock(product_id: str, user_id: str, quantity: int) -> str | None:
    client = get_redis()
    if not client:
        return None
    lock_id = str(uuid.uuid4())
    payload = json.dumps({"product_id": product_id, "user_id": user_id, "quantity": quantity})
    key = f"lock:{lock_id}"
    index_key = f"lock:byproduct:{product_id}"
    await client.set(key, payload, ex=LOCK_TTL_SECONDS)
    await client.sadd(index_key, lock_id)
    await client.expire(index_key, LOCK_TTL_SECONDS)
    return lock_id


async def get_locked_quantity(product_id: str) -> int:
    client = get_redis()
    if not client:
        return 0

    index_key = f"lock:byproduct:{product_id}"
    lock_ids = await client.smembers(index_key)
    total = 0
    stale = []
    for lock_id in lock_ids:
        raw = await client.get(f"lock:{lock_id}")
        if raw is None:
            stale.append(lock_id)
            continue
        total += json.loads(raw)["quantity"]

    if stale:
        await client.srem(index_key, *stale)
    return total


async def release_user_locks(product_id: str, user_id: str) -> None:
    client = get_redis()
    if not client:
        return

    index_key = f"lock:byproduct:{product_id}"
    lock_ids = await client.smembers(index_key)
    to_remove = []
    for lock_id in lock_ids:
        key = f"lock:{lock_id}"
        raw = await client.get(key)
        if raw is None:
            to_remove.append(lock_id)
            continue
        if json.loads(raw)["user_id"] == user_id:
            await client.delete(key)
            to_remove.append(lock_id)

    if to_remove:
        await client.srem(index_key, *to_remove)

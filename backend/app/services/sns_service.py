import asyncio
import json
import logging

import boto3

from app.config import settings

logger = logging.getLogger(__name__)

_sns_client = boto3.client("sns", region_name=settings.AWS_REGION) if settings.SNS_TOPIC_ARN else None


async def publish_order_created(order_id: str, items: list[dict], total: float, billing: dict) -> bool:
    if not _sns_client:
        return False
    payload = {"order_id": order_id, "items": items, "total": total, "billing": billing}
    try:
        await asyncio.to_thread(_sns_client.publish, TopicArn=settings.SNS_TOPIC_ARN, Message=json.dumps(payload))
        return True
    except Exception:
        logger.exception("Error publicando mensaje SNS para la orden %s", order_id)
        return False

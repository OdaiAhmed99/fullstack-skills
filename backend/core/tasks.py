from asgiref.sync import async_to_sync
from celery import shared_task
from channels.layers import get_channel_layer


@shared_task
def notify_user(user_id, payload):
    """Push a message to one user's websocket (see background-jobs skill)."""
    async_to_sync(get_channel_layer().group_send)(f"user_{user_id}", {"type": "notify", "payload": payload})

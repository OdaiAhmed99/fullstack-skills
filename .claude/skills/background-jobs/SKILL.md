---
name: background-jobs
description: Celery + Redis background and scheduled jobs. Use when work is slow (exports, emails, AI calls, reports) or must run on a schedule.
---
# Background jobs (Celery)

- Anything slower than ~300 ms or calling an outside service runs in `<app>/tasks.py`, never inside the request.
- The view answers **202** `{job_id}`; the result reaches the user through the websocket / notification, or a signed short-lived download link.
- Enqueue **after commit**: `transaction.on_commit(lambda: build_export.delay(obj.id))` - otherwise the worker may read a row that is not committed yet.
- Pass **ids**, never model instances. Re-load inside the task.
- Tasks are **idempotent** (safe to retry): check "already done" first. `autoretry_for=(ConnectionError,)`, `retry_backoff=True`, `max_retries=5`.
- Dedupe identical requests (same user + same filters within N minutes -> reuse the file) with a cache key.
- Schedules: `django-celery-beat` (DB-editable) or `CELERY_BEAT_SCHEDULE`; name them `<app>.<verb>_<noun>`.
- In Docker: `celery` worker and `beat` are separate services using the backend image.
- Tests: `task.apply(args=[...])` runs synchronously; mock outside services.

```python
@shared_task(bind=True, autoretry_for=(ConnectionError,), retry_backoff=True, max_retries=5)
def build_export(self, export_id):
    export = Export.objects.get(id=export_id)
    if export.file:          # idempotent: already built
        return export.file.url
    ...
```

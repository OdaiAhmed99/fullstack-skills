---
name: signals
description: When to use Django signals vs the services layer for side effects. Use when a save must trigger something else (seed lists, link tenant, audit, notify).
---
# Signals vs services

- **Signal**: a side effect that must happen *whoever* saves the row - seeding a new tenant's default lists, linking a new user to its tenant, audit rows.
- **Service call**: anything that is part of a user action (send "assigned" notification, change status). Explicit beats magic.
- Signals live in `<app>/signals.py`, connected in `apps.py` `ready()`. Guard with `if created:` and keep them tiny - call a service function.
- Never call the network from a signal; enqueue a task with `transaction.on_commit`.
- Seeding pattern: `defaults.py` list -> `post_save(Tenant)` seeds new tenants -> a **data migration** seeds existing ones. Both call the same function.
- Not-yet-built notifications are marked `# NOTIFY:` so they can be found later.

```python
# apps.py
def ready(self):
    from . import signals  # noqa: F401

# signals.py
@receiver(post_save, sender=Tenant)
def seed_lists(sender, instance, created, **kwargs):
    if created:
        services.seed_default_types(instance)
```

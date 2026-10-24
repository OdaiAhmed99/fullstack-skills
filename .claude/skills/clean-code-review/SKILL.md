---
name: clean-code-review
description: Clean-code and no-duplication review before a PR. Use after tests are green.
---
# Clean code review

Run `/code-review` on the diff, then check:
- [ ] No copied function / serializer / queryset - extract to `services/` or `core/`.
- [ ] Views are thin; logic lives in services.
- [ ] No raw `request.data[...]` in business logic.
- [ ] Names speak the domain (`assign_task`, not `handle_data`).
- [ ] No dead code, commented-out code or `print`.
- [ ] Comments say *why*, not *what*.
- [ ] Every list served once (shared-lookups); every table row flat.
- [ ] No own paginator, filter parser or cache helper - `core/` only.
- [ ] No `fields = "__all__"`; no response field the screen does not use.
- [ ] No N+1 queries.
- [ ] Frontend: calls only through `src/api/<app>/` + `src/api/shared/`; shared components responsive and not duplicated.
- [ ] Tests cover each decision.

Address each finding, or write down why it does not apply.

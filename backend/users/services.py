from django.contrib.auth import get_user_model
from django.db.models import Q

User = get_user_model()


def find_user(login):
    """Resolve what the user typed in the login box to one user, or None."""
    # TODO(you): decide how `login` maps to a user (see the note in the chat).
    raise NotImplementedError

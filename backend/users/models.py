from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models.functions import Lower


class User(AbstractUser):
    """Custom user from day one - swapping AUTH_USER_MODEL later means rewriting migrations."""

    email = models.EmailField(unique=True)

    class Meta:
        constraints = [
            # "Ali@x.com" and "ali@x.com" are the same person: login matches case-insensitively,
            # so the database must refuse both existing.
            models.UniqueConstraint(Lower("email"), name="users_email_ci_unique"),
            models.UniqueConstraint(Lower("username"), name="users_username_ci_unique"),
        ]

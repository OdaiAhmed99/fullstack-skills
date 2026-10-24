from django.contrib.auth import authenticate
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from . import services


class LoginSerializer(serializers.Serializer):
    """One field takes either the username or the email."""

    login = serializers.CharField()
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate(self, attrs):
        user = services.find_user(attrs["login"])
        # authenticate() also refuses inactive users; one message for every failure
        # so the API never reveals which usernames or emails exist.
        if user is None or authenticate(username=user.username, password=attrs["password"]) is None:
            raise serializers.ValidationError(_("Wrong username/email or password."))
        attrs["user"] = user
        return attrs


class UserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


def tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {"access": str(refresh.access_token), "refresh": str(refresh)}

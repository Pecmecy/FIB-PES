"""
    Module including the custom authentication backend for the user login.
"""

from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend


class EmailBackend(ModelBackend):
    """
    Custom authentication backend for user login.
    """

    def authenticate(self, request, username=None, password=None, **kwargs):
        user_model = get_user_model()
        try:
            # authenticate use by default the username field, but we are using the email field
            user = user_model.objects.get(email=username)
        except user_model.DoesNotExist:
            return None
        else:
            if user.check_password(password):
                return user
        return None

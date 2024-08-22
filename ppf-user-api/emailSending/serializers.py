"""
This file is used to serialize the data that is sent to the server.
"""

from rest_framework import serializers
from common.models.user import User
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_decode
from django.contrib.auth.models import User


class PasswordResetRequestSerializer(serializers.Serializer):
    """
    Serializer to request a password reset
    """

    email = serializers.EmailField()

    def validate_email(self, value):
        """
        Validation of the email field
        """
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("No user is associated with this email address.")
        return value


class SetNewPasswordSerializer(serializers.Serializer):
    """
    Serializer to set a new password
    """

    new_password = serializers.CharField(write_only=True, required=True)
    new_password_confirm = serializers.CharField(write_only=True, required=True)
    uidb64 = serializers.CharField(write_only=True)
    token = serializers.CharField(write_only=True)

    def validate(self, data):
        try:
            uid = urlsafe_base64_decode(data["uidb64"]).decode()
            user = User.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            raise serializers.ValidationError("Invalid token or user ID")

        if not default_token_generator.check_token(user, data["token"]):
            raise serializers.ValidationError("Invalid token")

        if data["new_password"] == "" or data["new_password_confirm"] == "":
            raise serializers.ValidationError("Password cannot be empty")

        if data["new_password"] != data["new_password_confirm"]:
            raise serializers.ValidationError("Passwords do not match")

        return data

"""
The serializers for the user login
    Returns:
        _type_: _description_
"""

from rest_framework import serializers


class UserLoginSerializer(serializers.Serializer):
    """
    Serializer for handling user login data.

    Args:
        Serializer: Base class for serializers in Django REST Framework.
    """

    email = serializers.EmailField()
    password = serializers.CharField(max_length=128, write_only=True)

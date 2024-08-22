from operator import is_

from api.serializers import UserRegisterSerializer
from common.models.user import User
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.response import Response


def generate_token(user):
    """
    Generate a token for a user.
    """
    # Find an active token for the user
    token = Token.objects.filter(
        user=user)  # pylint: disable=no-member
    if token.exists():
        token = token.delete()

    # Create a new token for the user
    token = Token.objects.create(
        user=user)  # pylint: disable=no-member
    token.save()
    return token


def get_or_create_from_google(data):
    # Check if user exists in the database
    user = User.objects.filter(email=data.get(
        "email"), typeOfLogin="google").first()
    if user:
        return user
    else:
        data.update({"username": str(data.get("email")).split("@")[0]})
        data.update({"typeOfLogin": "google"})
        data.update(
            {"first_name": str(data.get("Display name")).split(" ")[0]})
        last_name = str(data.get("Display name")).split(" ")[1:]
        if len(last_name) < 1:
            last_name = "google"
        else:
            last_name = last_name[0]
        data.update({"last_name": last_name})
        data.update({"email": data.get("email")})
        data.update({"password": "google"})
        data.update({"password2": "google"})
        data.update({"birthDate": "2000-01-01"})
        data.update({"profileImage": data.get("Photo URL")})

        serializedUser = UserRegisterSerializer(
            data=data)
        print(serializedUser.is_valid())
        if serializedUser.is_valid():
            user = serializedUser.save()
            return user
        else:
            print(serializedUser.errors)
            return user
        # Return the created user


def ger_or_create_from_facebook(data):
    # Check if user exists in the database
    user = User.objects.filter(email=data.get(
        "email"), typeOfLogin="facebook").first()
    if user:
        # User already exists, return the user
        return user
    else:
        data.update({"typeOfLogin": "facebook"})
        # User does not exist, create a new user
        serializedUser = UserRegisterSerializer(
            data=data)
        print(serializedUser.is_valid())
        if serializedUser.is_valid():
            user = serializedUser.save()
            return user
        else:
            print(serializedUser.errors)
            return user
        # Return the created user

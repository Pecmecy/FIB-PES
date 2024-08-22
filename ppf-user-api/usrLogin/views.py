"""
    This module provides an API endpoint for user login.
"""

from django.contrib.auth import authenticate
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from .service.social_logins import get_or_create_from_google, ger_or_create_from_facebook, generate_token
from common.models.user import User
from .serializers import UserLoginSerializer

# Create your views here.


class LoginAPIView(APIView):
    """
    The class that returns a user token, generating a new one if necessary.

    Args:
        APIView: Base class for handling HTTP requests.
    """

    @swagger_auto_schema(
        request_body=UserLoginSerializer,
        responses={
            200: openapi.Response(
                description="Token successfully created or updated",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={"token": openapi.Schema(
                        type=openapi.TYPE_STRING)},
                ),
            ),
            401: openapi.Response(
                description="Unauthorized or invalid credentials",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={"error": openapi.Schema(
                        type=openapi.TYPE_STRING)},
                ),
            ),
        },
    )
    def post(self, request):
        """
        Handle POST request for user login authentication.

        Parameters:
        - request: HTTP request object containing user login credentials.

        Returns:
        - Response: HTTP response object containing a token or error message.
        """
        serializer = UserLoginSerializer(data=request.data)

        if serializer.is_valid():
            email = serializer.validated_data.get("email")  # type: ignore
            password = serializer.validated_data.get(
                "password")  # type: ignore
            # authenticate use by default the username field, but we are using the email field
            user = authenticate(username=email, password=password)

            if user:
                # Check if the user is a base user (not a social login user)
                userLogged = User.objects.filter(
                    email=email).first()
                if userLogged and userLogged.typeOfLogin != "base":
                    return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

                generatedToken = generate_token(user)
                return Response({"token": generatedToken.key})
            # If user not found means that the credentials are invalid or
            # wrong username
            return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
        else:
            return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)


class GoogleLoginAPIView(APIView):
    """
    The class that logs in a user using Google credentials.
    """
    @swagger_auto_schema(
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "email": openapi.Schema(type=openapi.TYPE_STRING),
                "Display name": openapi.Schema(type=openapi.TYPE_STRING),
                "photoUrl": openapi.Schema(type=openapi.TYPE_STRING),
            },
            required=["email", "Display name", "photoUrl"],
        ),
        responses={
            200: openapi.Response(
                description="Token successfully created or updated",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={"token": openapi.Schema(
                        type=openapi.TYPE_STRING)},
                ),
            ),
        },
    )
    def post(self, request):
        """
        Handle POST request for user login using Google credentials.

        Parameters:
        - request: HTTP request object containing user login credentials.

        Returns:
        - Response: HTTP response object containing a token or error message.
        """
        # return Response({"message": "Google login not implemented yet"})
        user = get_or_create_from_google(request.data)
        if user:
            generatedToken = generate_token(user)
            return Response({"token": generatedToken.key})
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)


class FacebookLoginAPIView(APIView):
    """
    The class that logs in a user using Facebook credentials.
    """

    def post(self, request):
        """
        Handle POST request for user login using Facebook credentials.

        Parameters:
        - request: HTTP request object containing user login credentials.

        Returns:
        - Response: HTTP response object containing a token or error message.
        """
        user = ger_or_create_from_facebook(request.data)
        if user:
            generatedToken = generate_token(user)
            return Response({"token": generatedToken.key})
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

"""
This module contains the tests for the login.
"""

from urllib import response
from rest_framework.reverse import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from common.models.user import User

import json

from rest_framework.authtoken.models import Token


class LoginTest(APITestCase):
    """
    Test the login
    """

    def testLoginSucessfull(self):
        """
        Ensure the API call creates a auth token to the user
        """
        user = User.objects.create_user(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )

        url = reverse("login")
        data = {
            "email": "test@gmail.com",
            "password": "test",
        }

        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        token = Token.objects.get(user=user)
        self.assertEqual(message.get("token"), token.key)

    def testRenewToken(self):
        """
        Ensure the API call renews the token each time it is called
        """
        user = User.objects.create_user(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )

        url = reverse("login")
        data = {
            "email": "test@gmail.com",
            "password": "test",
        }

        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        token = Token.objects.get(user=user)
        self.assertEqual(message.get("token"), token.key)

        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        tokenNew = Token.objects.get(user=user)
        self.assertEqual(message.get("token"), tokenNew.key)
        self.assertNotEqual(token.key, tokenNew.key)

    def testLoginFailUserNotExist(self):
        """
        Ensure the API call fails when the user is not registered
        """

        url = reverse("login")
        data = {
            "email": "anyone@gmail.com",
            "password": "test",
        }

        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Invalid credentials")

    def testLoginFailPasswordIncorrect(self):
        """
        Ensure the API call fails when the password is incorrect
        """
        User.objects.create_user(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )

        url = reverse("login")
        data = {
            "email": "test@gmail.com",
            "password": "wrongpassword",
        }

        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Invalid credentials")

    def testNoEmail(self):
        """
        Ensure the API call fails when no email is provided
        """
        url = reverse("login")
        data = {
            "password": "test",
        }

        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

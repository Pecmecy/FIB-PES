"""
This module contains the tests for the users.
"""

from rest_framework.reverse import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from common.models.user import User

import json

from rest_framework.authtoken.models import Token


class RecoverPassword(APITestCase):
    """
    Test Create User
    """

    def setUp(self):
        self.userFail = User.objects.create(
            username="failUser",
            birthDate="1998-10-06",
            password="failUser",
            email="failUser@gmail.com",
        )
        self.token, _ = Token.objects.get_or_create(user=self.userFail)

    def testEmailFail(self):
        """
        Test Create User with email already in use
        """

        url = reverse("passwordReset")
        data = {
            "email": "mecagoentodo@gmail.com",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def testSetNewPasswordWithoutToken(self):
        """
        Test Set New Password with invalid token
        """

        url = reverse("setNewPassword")
        data = {
            "new_password": "newPassword",
            "new_password_confirm": "newPassword",
            "uidb64": "1",
            "token": "1",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def testSetNewPasswordWithoutPassword(self):
        """
        Test Set New Password with empty password
        """

        url = reverse("setNewPassword")
        data = {
            "new_password": "",
            "new_password_confirm": "",
            "uidb64": "1",
            "token": "1",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def testSetNewPasswordWithoutMatch(self):
        """
        Test Set New Password with passwords that do not match
        """

        url = reverse("setNewPassword")
        data = {
            "new_password": "newPassword",
            "new_password_confirm": "newPassword1",
            "uidb64": "1",
            "token": "1",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

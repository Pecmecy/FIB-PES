"""
This module contains the tests for the users.
"""

from rest_framework.reverse import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from common.models.user import User, Report

from rest_framework.authtoken.models import Token


class ReportTests(APITestCase):
    """
    Test Create User
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.token, _ = Token.objects.get_or_create(user=self.user)
        self.user2 = User.objects.create(
            username="test2", birthDate="1998-10-06", password="test2", email="test2@gmail.com"
        )
        self.token2, _ = Token.objects.get_or_create(user=self.user2)

    def testUserCannotDeleteOtherUserReport(self):
        """
        Ensure the API call returns an error if the user tries to delete another user.
        """
        report = Report.objects.create(reporter=self.user, reported=self.user2, comment="Nose")

        url = reverse("reportRetriever", kwargs={"pk": report.pk})
        headers = {"Authorization": f"Token {self.token2}"}
        response = self.client.delete(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def testUserCannotUpdateOtherUser(self):
        """
        Ensure the API call returns an error if the user tries to update another user.
        """

        report = Report.objects.create(reporter=self.user, reported=self.user2, comment="Nose")

        url = reverse("reportRetriever", kwargs={"pk": report.pk})
        data = {"comment": "string", "reported": "string"}
        headers = {"Authorization": f"Token {self.token2}"}
        responsePut = self.client.put(url, data, headers=headers)  # type: ignore
        self.assertEqual(responsePut.status_code, status.HTTP_403_FORBIDDEN)

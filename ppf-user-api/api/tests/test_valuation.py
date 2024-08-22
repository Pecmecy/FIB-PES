"""
This module contains the tests for the valuation.
"""

from lib2to3.pgen2 import driver
from os import rename
import re
import token
from urllib import response
from rest_framework.reverse import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from common.models.valuation import Valuation
from common.models.user import User, Driver, ChargerType, Preference
from common.models.route import Route

import json

from rest_framework.authtoken.models import Token


class CreateValuationTest(APITestCase):
    """
    Test module for creating a valuation.
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.tokenUser = Token.objects.create(user=self.user)
        self.mennekes = ChargerType.objects.create(chargerType="Mennekes")
        self.driver = Driver.objects.create(
            username="driver1",
            birthDate="1998-10-06",
            email="driver@gmail.com",
            password="driver",
            dni="12345678",
            preference=Preference.objects.create(),
            iban="ES662100999",
        )
        self.driver.chargerTypes.add(self.mennekes)
        self.tokenDriver = Token.objects.create(user=self.driver)
        self.route = Route.objects.create(
            driver_id=self.driver.pk,
            originLat=41.350450,
            originLon=2.132660,
            originAlias="SomeWhere",
            destinationLat=41.419860,
            destinationLon=2.2009346,
            destinationAlias="AnotherPlace",
            distance=100,
            duration=20,
            departureTime="2024-05-19T18:21:56.083Z",
            freeSeats=5,
            price=20.0,
        )
        self.route.passengers.add(self.user)

    def testSuccesfullCreateValuation(self):
        """
        Test to create a valuation with valid data.
        """

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.driver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Put",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser}",
        }

        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        message = json.loads(response.content.decode("utf-8"))
        valuation = Valuation.objects.get(pk=1)
        self.assertEqual(message.get("receiver"), valuation.receiver.pk)
        self.assertEqual(message.get("route"), valuation.route.pk)
        self.assertEqual(message.get("rating"), valuation.rating)
        self.assertEqual(message.get("comment"), valuation.comment)

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.user.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando user",
        }
        headers = {
            "Authorization": f"Token {self.tokenDriver}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        message = json.loads(response.content.decode("utf-8"))
        valuation = Valuation.objects.get(pk=2)
        self.assertEqual(message.get("receiver"), valuation.receiver.pk)
        self.assertEqual(message.get("route"), valuation.route.pk)
        self.assertEqual(message.get("rating"), valuation.rating)
        self.assertEqual(message.get("comment"), valuation.comment)

    def testReceiverNotExist(self):
        """
        Ensure the API call returns an error if the receiver does not exist.
        """

        url = reverse("valuationListCreate")
        data = {
            "receiver": 100,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando driver",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("Invalid receiver ID. User not found.", message.get("error"))

    def testCannotValuateYourself(self):
        """
        Ensure the API call returns an error if you try to rate yourself.
        """

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.user.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando myself",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("You cannot rate yourself.", message.get("error"))

    def testReceiverNotInRoute(self):
        """
        Ensure the API call returns an error if the receiver does not belong to the route.
        """

        receiver = User.objects.create(
            username="receiver",
            birthDate="1998-10-06",
            email="receiver@gmail.com",
            password="receiver",
        )

        url = reverse("valuationListCreate")
        data = {
            "receiver": receiver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando error",
        }
        headers = {
            "Authorization": f"Token {self.tokenDriver}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("The receiver is not part of the route.", message.get("error"))

    def testGiverNotInRoute(self):
        """
        Ensure the API call returns an error if the giver does not belong to the route.
        """

        giver = User.objects.create(
            username="giver",
            birthDate="1998-10-06",
            email="giver@gmail.com",
            password="giver",
        )
        tokenGiver = Token.objects.create(user=giver)

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.driver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando error",
        }
        headers = {
            "Authorization": f"Token {tokenGiver}",
        }

        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("The giver is not part of the route.", message.get("error"))

    def testPassengerCannotValueOtherPassenger(self):
        """
        Ensure the API call returns an error if you try to rate another passenger.
        """

        passenger = User.objects.create(
            username="passenger",
            birthDate="1998-10-06",
            email="passenger@gmail.com",
            password="passenger",
        )
        self.route.passengers.add(passenger)

        url = reverse("valuationListCreate")
        data = {
            "receiver": passenger.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando passenger",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser}",
        }

        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("A passenger cannot value other passengers.", message.get("error"))

    def testValuationAlreadyExist(self):
        """
        Ensure the API call returns an error if the valuation already exists.
        """

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.user.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando user",
        }
        headers = {
            "Authorization": f"Token {self.tokenDriver}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        response2 = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response2.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response2.content.decode("utf-8"))
        self.assertIn("You have already rated this user in this route.", message.get("error"))


class ListValuationTest(APITestCase):
    """
    Test module for listing valuations.
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.tokenUser = Token.objects.create(user=self.user)
        self.user2 = User.objects.create(
            username="test2", birthDate="1998-10-06", password="test2", email="test2@gmail.com"
        )
        self.tokenUser2 = Token.objects.create(user=self.user2)
        self.mennekes = ChargerType.objects.create(chargerType="Mennekes")
        self.driver = Driver.objects.create(
            username="driver1",
            birthDate="1998-10-06",
            email="driver@gmail.com",
            password="driver",
            dni="12345678",
            preference=Preference.objects.create(),
            iban="ES662100999",
        )
        self.driver.chargerTypes.add(self.mennekes)
        self.tokenDriver = Token.objects.create(user=self.driver)
        self.route = Route.objects.create(
            driver_id=self.driver.pk,
            originLat=41.350450,
            originLon=2.132660,
            originAlias="SomeWhere",
            destinationLat=41.419860,
            destinationLon=2.2009346,
            destinationAlias="AnotherPlace",
            distance=100,
            duration=20,
            departureTime="2024-05-19T18:21:56.083Z",
            freeSeats=5,
            price=20.0,
        )
        self.route.passengers.add(self.user)
        self.route.passengers.add(self.user2)

    def testListValuation(self):
        """
        Test to list valuations.
        """

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.driver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando driver",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser}",
        }

        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        data2 = {
            "receiver": self.driver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando driver",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser2}",
        }

        response2 = self.client.post(url, data2, format="json", headers=headers)  # type: ignore
        self.assertEqual(response2.status_code, status.HTTP_201_CREATED)

        url = reverse("userValuationList", kwargs={"user_id": self.driver.pk})
        headers = {
            "Authorization": f"Token {self.tokenDriver}",
        }
        response = self.client.get(url, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(len(message), 2)
        # First valuation
        self.assertEqual(message[0].get("receiver"), self.driver.pk)
        self.assertEqual(message[0].get("giver"), self.user.pk)
        self.assertEqual(message[0].get("rating"), 5)
        self.assertEqual(message[0].get("comment"), "Valuando driver")
        # Second valuation
        self.assertEqual(message[1].get("receiver"), self.driver.pk)
        self.assertEqual(message[1].get("giver"), self.user2.pk)
        self.assertEqual(message[1].get("rating"), 5)
        self.assertEqual(message[1].get("comment"), "Valuando driver")

    def testSelfListValuation(self):
        """
        Test to list the self valuations.
        """

        url = reverse("valuationListCreate")
        data = {
            "receiver": self.driver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando driver",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser}",
        }

        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        data2 = {
            "receiver": self.driver.pk,
            "route": self.route.pk,
            "rating": 5,
            "comment": "Valuando driver",
        }
        headers = {
            "Authorization": f"Token {self.tokenUser2}",
        }

        response2 = self.client.post(url, data2, format="json", headers=headers)  # type: ignore
        self.assertEqual(response2.status_code, status.HTTP_201_CREATED)

        url = reverse("myValuationList")
        headers = {
            "Authorization": f"Token {self.tokenDriver}",
        }

        response = self.client.get(url, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(len(message), 2)
        # First valuation
        self.assertEqual(message[0].get("receiver"), self.driver.pk)
        self.assertEqual(message[0].get("giver"), self.user.pk)
        self.assertEqual(message[0].get("rating"), 5)
        self.assertEqual(message[0].get("comment"), "Valuando driver")
        # Second valuation
        self.assertEqual(message[1].get("receiver"), self.driver.pk)
        self.assertEqual(message[1].get("giver"), self.user2.pk)
        self.assertEqual(message[1].get("rating"), 5)
        self.assertEqual(message[1].get("comment"), "Valuando driver")

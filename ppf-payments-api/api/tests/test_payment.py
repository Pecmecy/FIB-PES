from common.models import route
from rest_framework.test import APITestCase
from rest_framework.reverse import reverse
from rest_framework import status
from django.conf import settings

from common.models.user import ChargerType, User, Driver, Preference
from common.models.route import Route
from common.models.payment import Payment

import stripe
import json
from rest_framework.authtoken.models import Token


def createPaymentMethodId():
    stripe.api_key = settings.STRIPE_SECRET_KEY

    payment_method = stripe.PaymentMethod.create(type="card", card={"token": "tok_visa"})

    return payment_method.id


class CreatePaymentViewTest(APITestCase):
    """
    Test the CreatePaymentView view.
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test",
            birthDate="1998-10-06",
            password="test",
            email="test@gmail.com",
        )
        chargerType = ChargerType.objects.create(chargerType="Mennekes")
        self.driver = Driver.objects.create(
            username="driver1",
            birthDate="1998-10-06",
            email="driver@gmail.com",
            password="driver",
            dni="12345678",
            preference=Preference.objects.create(),
            iban="ES662100999",
        )
        self.driver.chargerTypes.add(chargerType)
        self.token, _ = Token.objects.get_or_create(user=self.user)
        self.route = Route.objects.create(
            driver=self.driver,
            originLat=41.389972,
            originLon=2.115333,
            originAlias="BSC - Supercomputing Center",
            destinationLat=42.244062,
            destinationLon=-6.269438,
            destinationAlias="Morla de la Valdería",
            price=10.0,
            distance=852896,
            duration=30177,
            departureTime="2024-10-06T10:00:00Z",
            freeSeats=4,
        )
        self.route.passengers.add(self.user)

    def testSuccessfulPayment(self):
        """
        Ensure the API call creates a payments in Stripe and a payment in the database.
        """

        paymentMethodId = createPaymentMethodId()
        url = reverse("process-payment")
        data = {
            "payment_method_id": paymentMethodId,
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))  # Decode the response to JSON
        self.assertEqual(message.get("message"), "Payment processed successfully.")

        payment_exists = Payment.objects.filter(user=self.user, route=self.route).exists()
        self.assertTrue(payment_exists)
        payment = Payment.objects.get(user=self.user, route=self.route)

        if payment is not None:
            self.assertEqual(payment.amount, self.route.price)
            self.assertEqual(payment.isRefunded, False)
            self.assertIsNotNone(payment.paymentIntentId)

    def testNeedsPaymentId(self):
        """
        Ensure the API call returns an error if the payment method id is not provided.
        """

        url = reverse("process-payment")
        data = {
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Payment method ID is required.")

    def testIncorrectPaymentId(self):
        """
        Ensure the API call returns an error if the payment method id is not incorrect.
        """

        url = reverse("process-payment")
        data = {
            "payment_method_id": "123",
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def testIncorrectRouteId(self):
        """
        Ensure the API call returns an error if the route id is not provided or it is incorrect.
        """

        paymentMethodId = createPaymentMethodId()
        url = reverse("process-payment")
        data = {
            "payment_method_id": paymentMethodId,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Route not exist.")

        data2 = {
            "payment_method_id": paymentMethodId,
            "route_id": 100,
        }
        response = self.client.post(url, data2, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Route not exist.")

    def testErrorPayTwice(self):
        """
        Ensure the API call returns an error if the user has already paid for the route.
        """

        paymentMethodId = createPaymentMethodId()
        url = reverse("process-payment")
        data = {
            "payment_method_id": paymentMethodId,
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "You have already paid for this route.")

    def testUnauthorized(self):
        """
        Ensure the API call returns an error if the user is not authenticated.
        """

        paymentMethodId = createPaymentMethodId()
        url = reverse("process-payment")
        data = {
            "payment_method_id": paymentMethodId,
            "route_id": self.route.pk,
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

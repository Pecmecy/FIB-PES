from email import message
from re import S
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


class CreateRefundViewTest(APITestCase):
    """
    Test the CreateRefundView view.
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

    def testSuccessfulRefund(self):
        """
        Ensure the API call refund a payment in Stripe and a payment in set as refunded.
        """
        paymentMethodId = createPaymentMethodId()
        url_payment = reverse("process-payment")
        data_payment = {
            "payment_method_id": paymentMethodId,
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }

        self.client.post(url_payment, data_payment, format="json", headers=headers)  # type: ignore

        url_refund = reverse("refund")
        data_refund = {
            "route_id": self.route.pk,
        }
        response = self.client.post(url_refund, data_refund, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))  # Decode the response to JSON
        self.assertEqual(message.get("message"), "Refund processed successfully.")

        payment = Payment.objects.get(user=self.user, route=self.route)
        self.assertEqual(payment.isRefunded, True)

    def testIncorrectRoute(self):
        """
        Ensure the API call returns an error if the route id is not provided or it is incorrect.
        """
        url = reverse("refund")
        data = {}
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Route not exist.")

        data2 = {
            "route_id": 999,
        }
        response = self.client.post(url, data2, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "Route not exist.")

    def testCantRefundUserNotPaid(self):
        """
        Ensure the API call returns an error if the user has not paid for the route and try to make a refund.
        """
        url = reverse("refund")
        data = {
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "User has not paid for this route.")

    def testErrorRefundTwice(self):
        """
        Ensure the API call returns an error if the user has already refunded the route.
        """
        paymentMethodId = createPaymentMethodId()
        url_payment = reverse("process-payment")
        data_payment = {
            "payment_method_id": paymentMethodId,
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }

        self.client.post(url_payment, data_payment, format="json", headers=headers)  # type: ignore

        url_refund = reverse("refund")
        data_refund = {
            "route_id": self.route.pk,
        }
        response = self.client.post(url_refund, data_refund, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        response = self.client.post(url_refund, data_refund, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "User has not paid for this route.")

    def testRefundDifferentPaymentSameUserRoute(self):
        """
        Ensure the API call keep one instance of the payment although the user has paid and refunded multiple times.
        """
        paymentMethodId = createPaymentMethodId()
        url_payment = reverse("process-payment")
        data_payment = {
            "payment_method_id": paymentMethodId,
            "route_id": self.route.pk,
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        self.client.post(url_payment, data_payment, format="json", headers=headers)  # type: ignore

        url_refund = reverse("refund")
        data_refund = {
            "route_id": self.route.pk,
        }
        self.client.post(url_refund, data_refund, format="json", headers=headers)  # type: ignore

        paymentMethodId2 = createPaymentMethodId()
        data_payment_2 = {
            "payment_method_id": paymentMethodId2,
            "route_id": self.route.pk,
        }
        self.client.post(url_payment, data_payment_2, format="json", headers=headers)  # type: ignore

        response = self.client.post(url_refund, data_refund, format="json", headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("message"), "Refund processed successfully.")

        payment = len(Payment.objects.filter(user=self.user, route=self.route, isRefunded=True))
        self.assertEqual(payment, 2)

    def testUnauthorized(self):
        """
        Ensure the API call returns an error if the user is not authenticated.
        """
        url_refund = reverse("refund")
        data_refund = {
            "route_id": self.route.pk,
        }
        response = self.client.post(url_refund, data_refund, format="json")  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

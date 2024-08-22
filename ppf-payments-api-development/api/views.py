"""
This module contains the views for the API endpoints related to payments.
"""

from datetime import datetime
from django.shortcuts import render
from django.conf import settings
from rest_framework.generics import CreateAPIView
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.status import (
    HTTP_200_OK,
    HTTP_400_BAD_REQUEST,
)
from common.models.user import User
from common.models.route import Route
from common.models.payment import Payment
import stripe
from .serializers import PaymentSerializer, RefundSerializer

# Create your views here.


def stripe_test(request):
    """
    Basic HTML page to test the Stripe integration.
    """
    return render(request, "stripe_test.html")


class CreatePaymentView(CreateAPIView):
    """
    Create a payment using Stripe API.
    """

    serializer_class = PaymentSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        # Token payment_method obtained from frontend
        paymentMethodId = request.data.get("payment_method_id")
        routeId = request.data.get("route_id")

        if not paymentMethodId:
            return Response(
                {"error": "Payment method ID is required."}, status=HTTP_400_BAD_REQUEST
            )

        if Route.objects.filter(id=routeId).exists() is False:
            return Response({"error": "Route not exist."}, status=HTTP_400_BAD_REQUEST)

        route = Route.objects.get(id=routeId)
        user = User.objects.get(id=request.user.id)
        priceForStripe = route.price * 100  # Stripe manage amount in cents

        # If a Payment is created and not Refunded, it means the user still in the route
        if Payment.objects.filter(user=user, route=route, isRefunded=False).exists():
            return Response(
                {"error": "You have already paid for this route."},
                status=HTTP_400_BAD_REQUEST,
            )

        stripe.api_key = settings.STRIPE_SECRET_KEY

        try:
            paymentIntent = stripe.PaymentIntent.create(
                amount=int(priceForStripe),
                currency="eur",
                payment_method=paymentMethodId,  # Payment method ID from the client
                confirm=True,  # Create and Confirm at the same time
                automatic_payment_methods={  # enable no redirect
                    "enabled": True,
                    "allow_redirects": "never",
                },
                # Specify a return_url if you want to redirect the user back to a specific page after successfull payment
            )
        except stripe.InvalidRequestError as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)

        if paymentIntent.status == "succeeded":
            try:
                Payment.objects.create(
                    user=user,
                    route=route,
                    amount=route.price,
                    date=datetime.now(),
                    description=f"Joined route {routeId} for ${route.price} at {datetime.now()}",
                    paymentIntentId=paymentIntent.id,
                )
            except Exception as e:
                return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)

            return Response({"message": "Payment processed successfully."}, status=HTTP_200_OK)
        else:
            return Response({"error": "Payment failed"}, status=HTTP_400_BAD_REQUEST)


class CreateRefundView(CreateAPIView):
    """
    Create a refund using Stripe API.
    """

    serializer_class = RefundSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = self.request.user
        routeId = request.data.get("route_id")

        if not Route.objects.filter(id=routeId).exists():
            return Response({"error": "Route not exist."}, status=HTTP_400_BAD_REQUEST)

        route = Route.objects.get(id=routeId)

        if not Payment.objects.filter(user=user, route=route, isRefunded=False).exists():
            return Response(
                {"error": "User has not paid for this route."}, status=HTTP_400_BAD_REQUEST
            )

        try:
            payment = Payment.objects.get(user=user, route=route, isRefunded=False)
            paymentIntentId = payment.paymentIntentId
        except Exception as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)

        stripe.api_key = settings.STRIPE_SECRET_KEY

        try:
            refund = stripe.Refund.create(
                payment_intent=paymentIntentId,
            )
        except stripe.InvalidRequestError as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)

        if refund.status == "succeeded":
            Payment.objects.filter(paymentIntentId=paymentIntentId).update(isRefunded=True)
            return Response({"message": "Refund processed successfully."}, status=HTTP_200_OK)
        else:
            return Response({"Refund failed"}, status=HTTP_400_BAD_REQUEST)

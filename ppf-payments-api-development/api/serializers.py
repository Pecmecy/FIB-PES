from rest_framework import serializers
from common.models.route import Route


class PaymentSerializer(serializers.Serializer):
    """
    The Payment serializer class

    Args:
        serializers (ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    payment_method_id = serializers.CharField(max_length=100)
    route_id = serializers.PrimaryKeyRelatedField(queryset=Route.objects.all())


class RefundSerializer(serializers.Serializer):
    """
    The Refund serializer class

    Args:
        serializers (ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    route_id = serializers.PrimaryKeyRelatedField(queryset=Route.objects.all())

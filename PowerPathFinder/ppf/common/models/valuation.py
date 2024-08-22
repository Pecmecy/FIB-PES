"""
Here is the common models for all the applications.

This will be shared through all the dockers and can be accesses by importing it.

__example: from common.models import Valuation
"""

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from .user import User
from .route import Route


class Valuation(models.Model):
    """
    Model for storing valuations given by users to users or drivers.
    """

    RATING_CHOICES = [
        (1, "1"),
        (2, "2"),
        (3, "3"),
        (4, "4"),
        (5, "5"),
    ]

    giver = models.ForeignKey(User, related_name="given_valuations", on_delete=models.CASCADE)
    receiver = models.ForeignKey(
        User,
        related_name="received_user_valuations",
        on_delete=models.CASCADE,
    )
    route = models.ForeignKey(Route, related_name="route_valuations", on_delete=models.CASCADE)
    rating = models.IntegerField(
        choices=RATING_CHOICES, validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField(blank=True)
    createdAt = models.DateTimeField(auto_now_add=True)

    class Meta:
        """
        Meta used to add the label so that the imports work correctly
        """

        app_label = "common"
        unique_together = ("giver", "receiver", "route")

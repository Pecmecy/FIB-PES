"""
Here is the common models for all the applications.

This will be shared through all the dockers and can be accesses by importing it.

__example: from common.models import Payment
Payment: Maintains a record of the payments made by users for routes.
"""

from django.db import models

from .user import User
from .route import Route


class Payment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    route = models.ForeignKey(Route, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateTimeField(auto_now_add=True)
    description = models.CharField(max_length=100)
    paymentIntentId = models.CharField(max_length=100, unique=True)
    isRefunded = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.user.username}'s payment of {self.amount} on {self.date}"

    class Meta:
        """
        Meta used to add the label so that the imports work correctly
        """

        app_label = "common"

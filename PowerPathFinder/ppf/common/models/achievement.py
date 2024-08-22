"""
Here is the common models for all the applications.

This will be shared through all the dockers and can be accesses by importing it.

__example: from common.models.achievement import Achievement
"""

from django.db import models
from .user import User


class Achievement(models.Model):
    title = models.CharField(max_length=100, unique=True)
    description = models.TextField()
    required_points = models.IntegerField()

    class Meta:
        app_label = "common"


class UserAchievementProgress(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    progress = models.IntegerField(default=0)
    achieved = models.BooleanField(default=False)
    date_achieved = models.DateTimeField(null=True, blank=True)

    class Meta:
        app_label = "common"
        unique_together = ("user", "achievement")

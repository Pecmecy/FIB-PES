from django.db import models

from .user import User
from .route import Route

class GoogleOAuth2Token(models.Model):
    """
    This model contains the OAuth2 tokens for the Google Calendar API
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    access_token = models.CharField(max_length=255)
    refresh_token = models.CharField(max_length=255)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        app_label = "common"


class GoogleCalendarEvent(models.Model):
    """
    This model contains the identifiers of the events created in the Google Calendar
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    route = models.ForeignKey(Route, on_delete=models.CASCADE)
    event_id = models.CharField(max_length=255)

    class Meta:
        app_label = "common"
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from common.models.calendar import GoogleOAuth2Token, GoogleCalendarEvent
from common.models.user import User
from django.conf import settings


def add_event_calendar(user, route, event_data):
    try:
        token = GoogleOAuth2Token.objects.get(user=user)
    except GoogleOAuth2Token.DoesNotExist:
        raise Exception("No tokens found for user")

    credentials = Credentials(
        token=token.access_token,
        refresh_token=token.refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=settings.CLIENT_ID,
        client_secret=settings.CLIENT_SECRET,
    )

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

        # Save the new access token and expiration
        token.access_token = credentials.token
        token.expires_at = credentials.expiry
        token.save()

    # Create a Google Calendar service object
    service = build("calendar", "v3", credentials=credentials)

    # Create a new event of the user's calendar
    created_event = service.events().insert(calendarId="primary", body=event_data).execute()

    userModel = User.objects.get(id=user.pk)
    # Save event id in DB
    GoogleCalendarEvent.objects.create(
        user=userModel, route=route, event_id=created_event["id"]
    )

    return created_event


def delete_event_calendar(user, route):
    try:
        event = GoogleCalendarEvent.objects.get(user=user, route=route)
    except GoogleCalendarEvent.DoesNotExist:
        raise Exception("No event found for this user and route")

    try:
        token = GoogleOAuth2Token.objects.get(user=user)
    except GoogleOAuth2Token.DoesNotExist:
        raise Exception("No tokens found for user")

    credentials = Credentials(
        token=token.access_token,
        refresh_token=token.refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=settings.CLIENT_ID,
        client_secret=settings.CLIENT_SECRET,
    )

    if credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

        # Save the new access token and expiration
        token.access_token = credentials.token
        token.expires_at = credentials.expiry
        token.save()

    # Create a Google Calendar service object
    service = build("calendar", "v3", credentials=credentials)

    # Delete the event from the user's calendar
    try:
        service.events().delete(calendarId="primary", eventId=event.event_id).execute()
        # Delete the event from the database
        event.delete()
        return True
    except Exception as e:
        raise Exception(f"Failed to delete event: {str(e)}")

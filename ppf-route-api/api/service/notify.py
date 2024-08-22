from enum import Enum

from common.models.route import Route
from requests import HTTPError, post
import logging

NOTIFY_API_URL = "http://user-api:8000/push/notify"


class Notification:
    """
    Represents a notification with a title and body.
    The class provides static methods to create different types of notifications.
    """

    class Priority(Enum):
        HIGH = "high"
        NORMAL = "normal"

    def __init__(self, title: str, body: str, priority: Priority = Priority.NORMAL):
        self.title = title
        self.body = body
        self.priority = priority

    @staticmethod
    def routeStarted(destination: str):
        title = "Route Started"
        body = f"The route to {destination} has started"
        return Notification(title, body, Notification.Priority.HIGH)

    @staticmethod
    def routeEnded(destination: str):
        title = "Route Ended"
        body = f"The route to {destination} has ended"
        return Notification(title, body)

    @staticmethod
    def routeCancelled(destination: str):
        title = "Route Canceled"
        body = f"The route to {destination} has been canceled"
        return Notification(title, body, Notification.Priority.HIGH)

    @staticmethod
    def passengerJoined(destination: str):
        title = "Passenger Joined"
        body = f"A passenger has joined your route to {destination}"
        return Notification(title, body)

    @staticmethod
    def passengerLeft(destination: str):
        title = "Passenger Left"
        body = f"A passenger has left your route to {destination}"
        return Notification(title, body)


def notify(user: str, title: str, body: str, priority: str):
    """
    Sends a notification to a certain user.

    Args:
        user (str): The username of the recipient.
        title (str): The title of the notification.
        body (str): The body content of the notification.

    Raises:
        HTTPError: If the request to send the notification fails.

    """
    try:
        # Send a http request to user-api to send a notification to a certain user
        response = post(
            NOTIFY_API_URL + f"/{user}",
            json={"user": user, "title": title, "body": body, "priority": priority},
        )
        response.raise_for_status()  # Raise an exception if the request was not successful
    except HTTPError as e:
        # Log the error message if the request fails
        logging.error(e.strerror)
        pass


def notifyPassengers(routeId: str, ntf: Notification):
    """
    Notifies all passengers of a given route.

    Args:
        routeId (str): The ID of the route.
        ntf (Notification): The notification object containing the title and body.

    Returns:
        None
    """
    # get route passengers user id
    route: Route | None = Route.objects.get(id=routeId)
    if route is not None:
        passengers = route.passengers.all()
        # Notify all passengers
        for passenger in passengers:
            notify(passenger.pk, ntf.title, ntf.body, ntf.priority.value)
    else:
        logging.error(f"Route with id {routeId} not found")


def notifyDriver(routeId: str, ntf: Notification):
    """
    Notifies the driver of a route about a passenger joining the route.

    Args:
        routeId (str): The ID of the route.
        ntf (Notification): The notification object containing the title and body.

    Returns:
        None
    """
    # get route driver user id
    route: Route | None = Route.objects.get(id=routeId)
    if route is not None:
        driver = route.driver.pk
        # Notify the driver that a passenger has joined the route
        notify(driver, ntf.title, ntf.body, ntf.priority.value)
    else:
        logging.error(f"Route with id {routeId} not found")

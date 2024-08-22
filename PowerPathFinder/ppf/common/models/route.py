"""
Data models definition for all PowerPathFinder services, this module serves as single source of
truth. Other services will introspect the DB in order to be up to date. It includes the following
models:

- Route: Describes the routes that drivers can create and passengers can join.
- RoutePassengers: Describes the passengers that are part of a route, records are created when
    users join to a route.
"""

from datetime import timedelta
from django.db import models
from django.db.models import Q

from .user import Driver, User


class RouteManager(models.Manager):
    """
    RouteManager is a custom Manager that adds 'table-level' functionality
    This managers will act as the entry point of the domain to the persistance layer
    https://docs.djangoproject.com/en/5.0/topics/db/managers/#custom-managers
    # See QuerySet API https://docs.djangoproject.com/en/5.0/ref/models/querysets/#queryset-api
    # See Filtered Relations https://docs.djangoproject.com/en/5.0/ref/models/querysets/#queryset-api
    # See Complex Lookups https://docs.djangoproject.com/en/5.0/topics/db/queries/#complex-lookups-with-q-objects
    """

    def byUser(self, userId):
        """
        returns all routes where the user is present either as driver or passenger
        """
        return self.get(Q(driver_id=userId) | Q(passengers__id__contains=userId))

    def active(self):
        """
        active queryset, retrieves all routes that ar not either cancelled or finalized
        """
        return self.filter(cancelled=False, finalized=False)

    def cancelled(self):
        """
        cancelled queryset, retrieves all routes that are cancelled
        """
        return self.filter(cancelled=True)

    def finalized(self):
        """
        finalized queryset, retrieves all routes that are finalized
        """
        return self.filter(finalized=True)

    def withSeats(self):
        """
        withSeats queryset, retrieves all routes that has at least one free seat
        """
        return self.filter(freeSeats__gt=0)


class Route(models.Model):
    """
    Route between two points, organized by a driver to be shared with passengers.
    """

    objects: RouteManager = RouteManager()  # Must assign the custom manager and specify the type

    driver = models.ForeignKey(Driver, on_delete=models.CASCADE)

    originLat = models.FloatField()
    originLon = models.FloatField()
    originAlias = models.CharField(max_length=100)

    destinationLat = models.FloatField()
    destinationLon = models.FloatField()
    destinationAlias = models.CharField(max_length=100)

    polyline = models.TextField()
    waypoints = models.JSONField(default=list)
    distance = models.PositiveIntegerField()
    duration = models.PositiveIntegerField()

    departureTime = models.DateTimeField()
    freeSeats = models.PositiveSmallIntegerField()
    price = models.FloatField(default=0.0)

    passengers = models.ManyToManyField(User, related_name="joined_routes")

    cancelled = models.BooleanField(default=False)
    finalized = models.BooleanField(default=False)

    createdAt = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = "common"

    def isFull(self):
        """
        Returns True if the route is full, False otherwise.
        """
        return self.freeSeats == 0

    def overlapsWith(self, routeId):  # TODO refactor to accept Route instance
        """
        Returns True if the route temporally overlaps with the route with the provided ID, False otherwise.
        """
        duration = timedelta(seconds=self.duration)
        route = Route.objects.get(id=routeId)
        if self.departureTime + duration >= route.departureTime:
            return True
        return False

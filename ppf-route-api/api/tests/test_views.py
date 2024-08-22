import datetime
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch

from common.models.route import Route
from common.models.user import Driver

from .payloads import CREATE_ROUTE_PAYLOAD
from .payloads import CREATE_ROUTE_PREVIEW_RESPONSE
from .payloads import CREATE_ROUTE_RESPONSE
from .payloads import MAPS_COMPUTE_RESPONSE
from .payloads import CREATE_ROUTE_PREVIEW_PAYLOAD


class RouteCreateTestCase(APITestCase):
    """
    Test case for the route list create view.
    """

    def setUp(self) -> None:
        # TODO have fixtures for this?
        driver = Driver.objects.create(
            username="test", birthDate=datetime.date(1998, 10, 6), password="testpaswordvalid"
        )
        driver.save()

        return super().setUp()

    def testCreateRoute(self):
        """
        Test case for creating a route.
        """
        data = CREATE_ROUTE_PAYLOAD

        with patch("api.views.computeMapsRoute") as mock_computeRoute:
            mock_computeRoute.return_value = MAPS_COMPUTE_RESPONSE
            response = self.client.post("/routes", data, format="json")
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
            self.assertEqual(response.data, CREATE_ROUTE_RESPONSE)

    def testCreateRoutePreview(self):
        """
        Test case for creating a preview route.
        """
        with patch("api.views.computeMapsRoute") as mock_computeRoute:
            mock_computeRoute.return_value = MAPS_COMPUTE_RESPONSE
            response = self.client.post("/routes", CREATE_ROUTE_PREVIEW_PAYLOAD, format="json")
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.data, CREATE_ROUTE_PREVIEW_RESPONSE)

    def testCreateOverlapingRoute(self):
        """
        Test case for creating a route that overlaps with an existing route from the same driver.
        """
        route = Route.objects.create(
            driver=Driver.objects.get(username="test"),
            originLat=1.0,
            originLon=1.0,
            originAlias="Perú",
            destinationLat=2.0,
            destinationLon=2.0,
            destinationAlias="Perú 2",
            polyline="",
            distance=999,
            duration=10800,  # 3 hours
            departureTime="2024-10-06T09:00:00Z",
            freeSeats=4,
            price=1000000,
        )

        # Try to create a route that overlaps with the previous one
        response = self.client.post("/routes", CREATE_ROUTE_PAYLOAD, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("message"), "Route overlaps in time with another route")

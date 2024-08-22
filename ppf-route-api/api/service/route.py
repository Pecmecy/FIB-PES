import json
import logging
from typing import Union

import polyline
import requests
from api import GoogleMapsRouteClient
from api.serializers import CreateRouteSerializer, PreviewRouteSerializer
from api.service.dijkstra import dijkstra
from api.service.kPowerFinder import kPowerFinder
from common.models.charger import ChargerLocationType, LocationCharger
from common.models.route import Route
from common.models.user import Driver, User

# Dont remove, it is use for migrate well
from django.utils import timezone
from geopy.distance import distance
from google.maps.routing_v2 import ComputeRoutesRequest, ComputeRoutesResponse
from google.maps.routing_v2 import Route as GRoute
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import ValidationError

X_GOOGLE_FIELDS = (
    "x-goog-fieldmask",
    "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
)

from rest_framework.exceptions import APIException


class NoRouteFound(APIException):
    status_code = 404
    default_detail = "No routes found"
    default_code = "no_routes_found"


def buildMapsRouteRequest(
    serializer: Union[PreviewRouteSerializer, CreateRouteSerializer]
) -> ComputeRoutesRequest:
    """
    Creates a ComputeRoutesRequest object based on the passed data.

    Returns:
        ComputeRoutesRequest: The created ComputeRoutesRequest object.
    """
    mapping = {
        "origin": {
            "location": {
                "lat_lng": {
                    "latitude": serializer.validated_data.get("originLat"),  # type: ignore
                    "longitude": serializer.validated_data.get("originLon"),  # type: ignore
                }
            }
        },
        "destination": {
            "location": {
                "lat_lng": {
                    "latitude": serializer.validated_data.get("destinationLat"),  # type: ignore
                    "longitude": serializer.validated_data.get("destinationLon"),  # type: ignore
                }
            }
        },
    }
    computeRoutesRequest = ComputeRoutesRequest(mapping)
    return computeRoutesRequest


def deserializeMapsRoutesResponse(mapsRoute: ComputeRoutesResponse):
    """
    Derializes a ComputeRoutesResponse object into the serializer.

    Args:
        response (ComputeRoutesResponse): The ComputeRoutesResponse object to serialize.
    """
    assert isinstance(mapsRoute, ComputeRoutesResponse), "Wrong type for response parameter"

    if not mapsRoute.routes:
        raise NoRouteFound()

    route: GRoute = mapsRoute.routes[0]
    return {
        "polyline": route.polyline.encoded_polyline,
        "duration": route.duration.seconds,
        "distance": route.distance_meters,
    }


def computeMapsRoute(serializer: Union[PreviewRouteSerializer, CreateRouteSerializer]):
    """
    Computes the route using the Google Maps API based on the provided serializer.

    Args:
        serializer (Union[CreatePreviewRouteSerializer, CreateRouteSerializer]): The serializer object containing the route information.

    Returns:
        The deserialized response from the Google Maps API.
    """
    mapsPayload = buildMapsRouteRequest(serializer)

    # Initialize request argument(s)
    request = ComputeRoutesRequest(mapping=mapsPayload)
    response = GoogleMapsRouteClient.compute_routes(request=request, metadata=[X_GOOGLE_FIELDS])

    # Deserialize the response from the Google Maps API and send it back to the client
    return deserializeMapsRoutesResponse(response)


def buildMapsRouteRequestChargers(path: list[dict[str, Union[str, float]]]):
    """
    Creates a payload for the Google Maps API.

    Args:
        path (list): The path from the Dijkstra's algorithm.
        origin (str): The origin.
        destination (str): The destination.
    """

    # Remove the origin and destination from the path
    waypoints = path[1:-1]
    origin = path[0]
    destination = path[-1]

    # Format the waypoints into a string
    # waypoints_str = '|'.join(waypoints)
    intermediates = []
    for point in waypoints:
        intermediates.append(
            {
                "location": {
                    "lat_lng": {
                        "latitude": point["latitude"],
                        "longitude": point["longitude"],
                    }
                }
            }
        )

    mapping = {
        "origin": {
            "location": {
                "lat_lng": {
                    "latitude": origin["latitude"],
                    "longitude": origin["longitude"],
                }
            }
        },
        "destination": {
            "location": {
                "lat_lng": {
                    "latitude": destination["latitude"],
                    "longitude": destination["longitude"],
                }
            }
        },
        "intermediates": [],
    }
    mapping["intermediates"] = intermediates
    computeRoutesRequest = ComputeRoutesRequest(mapping)
    return computeRoutesRequest


def computeOptimizedRoute(
    serializer: Union[PreviewRouteSerializer, CreateRouteSerializer], driverId: int
):
    """
    Creates a ComputeOptimizedRoutesRequest object based on the passed data.

    Returns:
        ComputeOptimizedRoutesRequest: The created ComputeOptimizedRoutesRequest object.
    """
    # Refactor to outside method
    mapsPayload = buildMapsRouteRequest(serializer)
    request = ComputeRoutesRequest(mapping=mapsPayload)
    response = GoogleMapsRouteClient.compute_routes(request=request, metadata=[X_GOOGLE_FIELDS])

    # Decode the polyline
    decodedPolyline = polyline.decode(response.routes[0].polyline.encoded_polyline)

    user = Driver.objects.get(id=driverId)
    autonomy = user.autonomy

    finalRoute: list[dict[str, str | float]] = []
    origin_to_destination_distance = distance(decodedPolyline[0], decodedPolyline[-1]).km

    # If the distance is less than the autonomy, return a direct route
    if origin_to_destination_distance <= autonomy:
        finalRoute = [
            {
                "charger": "origin",
                "latitude": decodedPolyline[0][0],
                "longitude": decodedPolyline[0][1],
            },
            {
                "charger": "destination",
                "latitude": decodedPolyline[-1][0],
                "longitude": decodedPolyline[-1][1],
            },
        ]

    else:
        # Get route bounds
        bounds = getRouteBounds(decodedPolyline)

        # Convert ManyToManyRelatedManager to list
        driverChargerTypes = list(user.chargerTypes.all())
        chargersInArea = calculateChargerPoints(bounds, driverChargerTypes)

        # Create list with possible route points
        # [0] is origin, [-1] is destination
        potentialWaypoints = {"origin": decodedPolyline[0]}
        for charger in chargersInArea:
            potentialWaypoints[f"{charger['id']}"] = (charger["latitud"], charger["longitud"])
        potentialWaypoints["destination"] = decodedPolyline[-1]

        finalRoute = computeChargersRoute(potentialWaypoints, autonomy)

    mapsPayload = buildMapsRouteRequestChargers(finalRoute)
    request = ComputeRoutesRequest(mapping=mapsPayload)
    response = GoogleMapsRouteClient.compute_routes(request=request, metadata=[X_GOOGLE_FIELDS])

    routeData = deserializeMapsRoutesResponse(response)
    waypoints = finalRoute[1:-1]
    return routeData, waypoints


def getRouteBounds(decodedPolyline: list):
    """
    Returns the area of the route.

    Args:
        decodedPolyline (list): The decoded polyline.
    """

    minLat = decodedPolyline[0][0]
    maxLat = decodedPolyline[0][0]
    minLong = decodedPolyline[0][1]
    maxLong = decodedPolyline[0][1]

    for coord in decodedPolyline:
        maxLat = max(maxLat, coord[0])
        minLat = min(minLat, coord[0])
        maxLong = max(maxLong, coord[1])
        minLong = min(minLong, coord[1])

    # Shouthwest: lower left corner, Northeast: upper right corner
    return {"southwest": [minLat, minLong], "northeast": [maxLat, maxLong]}


def calculateChargerPoints(bounds: dict, chargerTypes: list):
    """
    Returns the charger points within the area of the route.

    Args:
        bounds (dict): The bounds of the route.
    """
    try:
        chargerTypeObjs = ChargerLocationType.objects.filter(chargerType__in=chargerTypes)
    except ChargerLocationType.DoesNotExist:
        raise APIException()
    # Get the charger points
    chargerPoints = LocationCharger.objects.filter(
        connectionType__in=chargerTypeObjs,
        latitud__gte=bounds["southwest"][0],
        latitud__lte=bounds["northeast"][0],
        longitud__gte=bounds["southwest"][1],
        longitud__lte=bounds["northeast"][1],
    ).values()
    return list(chargerPoints)


def vectDistance(point1: list[float], point2: list[float]):
    return distance(list(point1), list(point2)).kilometers


def computeChargersRoute(routePoints: dict[str, tuple[float, float]], autonomy: float):
    """
    Returns the possible routes based on the charger points.

    Args:
        routePoints (dict): The route points.
    """
    # Dijkstra candidate points and a distance matrix between them
    try:
        filteredRoutePoints = kPowerFinder(
            autonomy,
            routePoints,
        )
    except ValueError:
        raise NoRouteFound("Destination is unreachable")

    # Label the charger points with it's ID
    labeledChargers: dict[str, tuple[float, float]] = {}
    for coord in filteredRoutePoints:
        # get the charger id from db and add it to the dict
        try:
            chargerInstance = LocationCharger.objects.filter(
                latitud=coord[0], longitud=coord[1]
            ).first()
            if not chargerInstance:
                raise LocationCharger.DoesNotExist
        except LocationCharger.DoesNotExist:
            raise APIException()  # and it should exist

        labeledChargers[chargerInstance.pk] = coord

    # Add the origin and destination to the dict
    labeledChargers["origin"] = routePoints["origin"]
    labeledChargers["destination"] = routePoints["destination"]

    # We get the distances between the points
    labeledDistances: dict[str, dict[str, float]] = {}
    for key1, value1 in labeledChargers.items():
        labeledDistances[key1] = {}
        for key2, value2 in labeledChargers.items():
            labeledDistances[key1][key2] = distance(value1, value2).kilometers

    finalPoints = dijkstra(labeledDistances, "origin", "destination", autonomy)

    path: list[dict[str, str | float]] = []
    for point in finalPoints:
        path.append(
            {
                "charger": point,
                "latitude": labeledChargers[point][0],
                "longitude": labeledChargers[point][1],
            }
        )
    return path


def validateJoinRoute(routeId: int, passengerId: int):
    """
    Validates if a user can join a route.

    Args:
        route_id (int): The ID of the route.
        user_id (int): The ID of the user.
    """
    route = Route.objects.get(id=routeId)
    if route.driver.pk == passengerId:
        raise ValidationError("Driver can't join the route", 400)

    if route.isFull():
        raise ValidationError("Route is full", 400)

    if route.passengers.filter(id=passengerId).exists():
        raise ValidationError("User is already in the route", 400)

    if route.cancelled:
        raise ValidationError("You can not join a cancelled route", 400)

    if route.finalized:
        raise ValidationError("You can not join a finalized route", 400)

    # check if the user is already in a route that overlaps with the current route
    joinedRoutes = route.passengers.filter(id=passengerId)
    for joinedRoute in joinedRoutes:
        if route.overlapsWith(joinedRoute.route):
            raise ValidationError(
                "User is already in a route that overlaps with the current route", 400
            )


def joinRoute(routeId: int, passengerId: int, paymentMethodId: str):
    """
    Joins a user to a route after payment is successfull.

    Args:
        route_id (int): The ID of the route.
        user_id (int): The ID of the user.
    """
    try:
        route = Route.objects.get(id=routeId)
    except Route.DoesNotExist:
        raise ValidationError("Route does not exist", 400)

    try:
        token = Token.objects.get(user_id=passengerId)
    except Token.DoesNotExist:
        raise ValidationError("User does not have a token", 400)

    url = "http://payments-api:8000/process_payment/"
    data = {
        "payment_method_id": paymentMethodId,
        "route_id": routeId,
    }
    headers = {"Content-Type": "application/json", "Authorization": "Token " + token.key}
    response = requests.post(url, data=json.dumps(data), headers=headers)

    if response.status_code != 200:
        raise ValidationError("Payment failed and user did not join the route", 400)

    passenger = User.objects.get(id=passengerId)
    route.passengers.add(passenger)


def leaveRoute(routeId: int, passengerId: int):
    """
    Leaves a user from a route.

    Args:
        route_id (int): The ID of the route.
        user_id (int): The ID of the user.
    """
    route = Route.objects.get(id=routeId)
    if not route.passengers.filter(id=passengerId).exists():
        raise ValidationError("User is not in the route", 400)

    # Only refund if more than 24 hours before the departure time
    if (route.departureTime - timezone.now()).days >= 1:
        try:
            token = Token.objects.get(user_id=passengerId)
        except Token.DoesNotExist:
            raise ValidationError("User does not have a token", 400)

        url = "http://payments-api:8000/refund/"
        data = {
            "route_id": routeId,
        }
        headers = {"Content-Type": "application/json", "Authorization": "Token " + token.key}
        response = requests.post(url, data=json.dumps(data), headers=headers)

        if response.status_code != 200:
            raise ValidationError("Refund failed and User did not leave the route", 400)

    route.passengers.remove(User.objects.get(id=passengerId))


def forcedLeaveRoute(routeId: int, passengerId: int):
    """
    Forces a user to leave a route.

    Args:
        route_id (int): The ID of the route.
        user_id (int): The ID of the user.
    """
    route = Route.objects.get(id=routeId)
    if not route.passengers.filter(id=passengerId).exists():
        raise ValidationError("User is not in the route", 400)

    try:
        token = Token.objects.get(user_id=passengerId)
    except Token.DoesNotExist:
        raise ValidationError("User does not have a token", 400)

    url = "http://payments-api:8000/refund/"
    data = {
        "route_id": routeId,
    }
    headers = {"Content-Type": "application/json", "Authorization": "Token " + token.key}
    requests.post(url, data=json.dumps(data), headers=headers)

    # If refund fails, user is still removed from the route.
    # Contact us by email to resolve the issue.
    route.passengers.remove(User.objects.get(id=passengerId))


def createChatRoom(routeId: int, driverId: int, routeName: str):
    """
    Creates a chat room for a route.

    Args:
        route_id (int): The ID of the route.
    """
    response = requests.post(
        "http://chat-engine:8000/room",
        json={"id": routeId, "driver": driverId, "name": routeName},
    )
    if response.status_code != 201:
        logging.warning("Chat room creation failed")

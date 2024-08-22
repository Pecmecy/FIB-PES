from .polyline import POLYLINE

MAPS_COMPUTE_RESPONSE = {"routes": [{"distanceMeters": 852896, "duration": "30177s", "polyline": POLYLINE}]}

CREATE_ROUTE_PAYLOAD = {
    "driver": "1",
    "originAlias": "BSC - Supercomputing Center",
    "originLat": 41.389972,
    "originLon": 2.115333,
    "destinationAlias": "Morla de la Valdería",
    "destinationLat": 42.244062,
    "destinationLon": -6.269438,
    "departureTime": "2024-10-06T10:00:00Z",
    "freeSeats": 4,
    "price": 63.50,
}

CREATE_ROUTE_RESPONSE = {
    "routeId": "1",
    "driver": "1",
    "originAlias": "BSC - Supercomputing Center",
    "originLatitude": 41.389972,
    "originLongitude": 2.115333,
    "destinationAlias": "Morla de la Valdería",
    "destinationLatitude": 42.244062,
    "destinationLongitude": -6.269438,
    "departureTime": "2024-10-06T10:00:00Z",
    "freeSeats": 4,
    "price": 63.50,
    "distance": 852896,
    "duration": 30177,
    "polyline": POLYLINE,
}

CREATE_ROUTE_PREVIEW_PAYLOAD = {
    "originLatitude": 41.389972,
    "originLongitude": 2.115333,
    "destinationLatitude": 42.244062,
    "destinationLongitude": -6.269438,
}

CREATE_ROUTE_PREVIEW_RESPONSE = {
    "polyline": POLYLINE,
    "duration": 30177,
    "distance": 852896,
}

RETRIEVE_ROUTE_RESPONSE = CREATE_ROUTE_RESPONSE

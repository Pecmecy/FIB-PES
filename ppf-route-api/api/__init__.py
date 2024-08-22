import os
from google.maps.routing_v2 import RoutesClient

CLIENT_OPTIONS = {
    "api_key": os.environ.get("BACKEND_MAPS_API", "none"),
    "quota_project_id": os.environ.get("PROJECT_ID", "none"),
}
GoogleMapsRouteClient = RoutesClient(client_options=CLIENT_OPTIONS)

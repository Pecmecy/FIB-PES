from rest_framework import authentication, permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

from api.v2.views import ListRoutes
from api.views import (
    FinishRoute,
    NearbyChargersView,
    RouteCancelView,
    LicitacioService,
    RoutePassengersList,
    RouteJoinView,
    RouteLeaveView,
    RouteListCreateView,
    RoutePassengersList,
    RoutePreviewView,
    RouteRetrieveView,
    RouteValidateJoinView,
    ExchangeCodeView,
)
from django.urls import path

urlpatterns = [
    path("routes", RouteListCreateView.as_view(), name="route-list-create"),
    path("routes/preview", RoutePreviewView.as_view(), name="route-list-create"),
    path("routes/<int:pk>", RouteRetrieveView.as_view(), name="route-detail"),
    path(
        "routes/<int:pk>/validate_join", RouteValidateJoinView.as_view(), name="route-validate-join"
    ),
    path("routes/<int:pk>/join", RouteJoinView.as_view(), name="route-join"),
    path("routes/<int:pk>/leave", RouteLeaveView.as_view(), name="route-leave"),
    path("v2/routes", ListRoutes.as_view(), name="list-routes-v2"),
    path("routes/<int:pk>/passengers", RoutePassengersList.as_view(),
         name="route-list-passengers"),
    path("routes/<int:pk>/cancel", RouteCancelView.as_view(), name="route-cancel"),
    path("routes/<int:pk>/finish", FinishRoute.as_view(), name="route-finish"),
]


schema_view = get_schema_view(
    openapi.Info(
        title="Routes API",
        default_version="v1",
        description="The routes API provides a way to compute routes between two points.",
        terms_of_service="https://www.google.com/policies/terms/",
        license=openapi.License(name="Apache 2.0 License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
    authentication_classes=[authentication.TokenAuthentication],
)

urlpatterns = urlpatterns + [
    path("swagger<format>/", schema_view.without_ui(cache_timeout=0),
         name="schema-json"),
    path("swagger/", schema_view.with_ui("swagger",
         cache_timeout=0), name="schema-swagger-ui"),
    path("redoc/", schema_view.with_ui("redoc",
         cache_timeout=0), name="schema-redoc"),
    path("chargers/", NearbyChargersView.as_view(), name="chargers"),
    path("chargers/<int:pk>/report",
         LicitacioService.as_view(), name="charger-detail"),
    path("calendar_token", ExchangeCodeView.as_view(), name="calendar_token"),
]

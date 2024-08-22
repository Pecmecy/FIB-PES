"""
URL configuration for paymentsApi project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.urls import path
from drf_yasg import openapi
from drf_yasg.views import get_schema_view
from rest_framework import authentication, permissions
from api import views

schema_view = get_schema_view(
    openapi.Info(
        title="Payment API",
        default_version="v1",
        description="The payments API provides a way to handle all about payments.",
        terms_of_service="https://www.example.com/terms/",
        license=openapi.License(name="Apache 2.0 License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
    authentication_classes=[authentication.TokenAuthentication],
)

urlpatterns = [
    path("swagger/", schema_view.with_ui("swagger", cache_timeout=0), name="schema-swagger-ui"),
    path("redoc/", schema_view.with_ui("redoc", cache_timeout=0), name="schema-redoc"),
    path("process_payment/", views.CreatePaymentView.as_view(), name="process-payment"),
    path("stripe_test/", views.stripe_test, name="stripe_test"),
    path("refund/", views.CreateRefundView.as_view(), name="refund"),
]

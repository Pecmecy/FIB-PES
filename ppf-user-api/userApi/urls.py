"""
URL configuration for userApi project.

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

from api import urls as apiUrls
from django.contrib import admin
from django.urls import include, path
from drf_yasg import openapi
from drf_yasg.views import get_schema_view
from emailSending import urls as emailSendingUrls
from rest_framework import authentication, permissions
from usrLogin import urls as usrLoginUrls
from achievement import urls as achievementUrls

schema_view = get_schema_view(
    openapi.Info(
        title="User API",
        default_version="v1",
        description="The users API provides a way to hanlde all about users.",
        license=openapi.License(name="Apache 2.0 License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
    authentication_classes=[authentication.TokenAuthentication],
)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("swagger/", schema_view.with_ui("swagger", cache_timeout=0), name="schema-swagger-ui"),
    path("redoc/", schema_view.with_ui("redoc", cache_timeout=0), name="schema-redoc"),
    path("", include(apiUrls)),
    path("login/", include(usrLoginUrls)),
    path("", include(emailSendingUrls)),
    path("", include(achievementUrls)),
]

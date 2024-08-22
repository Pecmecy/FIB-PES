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

from api import views
from django.urls import path

urlpatterns = [
    path("logut/", views.Logout.as_view(), name="logout"),
    path("users/", views.UserListCreate.as_view(), name="userListCreate"),
    path("drivers/", views.DriverListCreate.as_view(), name="driverListCreate"),
    path("drivers/<int:pk>/", views.DriverRetriever.as_view(), name="driverRetriever"),
    path("users/<int:pk>/", views.UserRetriever.as_view(), name="userRetriever"),
    path("reports/", views.ReportListCreate.as_view(), name="reportListCreate"),
    path("reports/<int:pk>/", views.ReportRetriever.as_view(), name="reportRetriever"),
    path("users/self/", views.UserIdRetriever.as_view(), name="userIdRetriever"),
    path("valuate/", views.ValuationListCreate.as_view(), name="valuationListCreate"),
    path("self/valuations/", views.MyValuationList.as_view(), name="myValuationList"),
    path(
        "users/<int:user_id>/valuations/",
        views.UserValuationList.as_view(),
        name="userValuationList",
    ),
    path("push/register/<int:pk>", views.RegisterFCMToken.as_view(), name="registerFCMToken"),
    path("push/notify/<int:pk>", views.SendFCMNotification.as_view(), name="notifyUser"),
    path("users/<int:pk>/avatar", views.UserModifyAvatar.as_view(), name="userModifyAvatar"),
    path("user-to-driver/", views.UserToDriver.as_view(), name="userToDriver"),
    path("driver-to-user/", views.DriverToUser.as_view(), name="driverToUser"),
]

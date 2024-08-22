"""
This file contains all the views to implement the api
"""

from api.notifications.push_controller import PushController
from common.models.achievement import UserAchievementProgress
from common.models.route import Route
from common.models.user import ChargerType, Driver, Preference, Report, User
from common.models.valuation import Valuation
from django.contrib.auth import logout
from django.forms import model_to_dict
from django.shortcuts import get_object_or_404
from drf_yasg.utils import swagger_auto_schema
from firebase_admin.exceptions import FirebaseError
from rest_framework import generics, status
from rest_framework.authentication import TokenAuthentication
from rest_framework.filters import OrderingFilter, SearchFilter
from rest_framework.generics import (
    CreateAPIView,
    GenericAPIView,
    ListAPIView,
    ListCreateAPIView,
    RetrieveUpdateDestroyAPIView,
    UpdateAPIView,
)
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.status import (
    HTTP_200_OK,
    HTTP_201_CREATED,
    HTTP_400_BAD_REQUEST,
    HTTP_403_FORBIDDEN,
    HTTP_500_INTERNAL_SERVER_ERROR,
)
from rest_framework.views import APIView

from .serializers import (
    DriverRegisterSerializer,
    DriverSerializer,
    FCMessageSerializer,
    FCMTokenSerializer,
    ReportSerializer,
    UserImageUpdateSerializer,
    UserRegisterSerializer,
    UserSerializer,
    UserToDriverSerializer,
    ValuationRegisterSerializer,
    ValuationSerializer,
)

pushController = PushController()


class UserListCreate(ListCreateAPIView):
    """
    The class that will generate a list of all the users and create if needed

    Args:
        generics (ListAPIView): This generates a list of users and pass it as json for the response
    """

    queryset = User.objects.all()
    serializer_class = UserSerializer
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ["username"]
    order_fields = ["points", "createdAt", "updatedAt"]

    def get_serializer_class(self):
        if self.request.method == "POST":
            return UserRegisterSerializer
        return super().get_serializer_class()


class UserModifyAvatar(UpdateAPIView):
    """
    The class that will modify the avatar of a user

    Args:
        generics (UpdateAPIView): This updates a user and pass it as json for the response
    """

    queryset = User.objects.all()
    serializer_class = UserImageUpdateSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.id != request.user.id:
            return Response(
                data={"error": "You can only update your own user account."},
                status=HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)


class DriverListCreate(ListCreateAPIView):
    """
    The class that will generate a list of all the drivers and create if needed

    Args:
        generics (ListAPIView): This generates a list of users and pass it as json for the response
    """

    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ["username"]
    order_fields = ["driverPoints", "createdAt", "updatedAt"]

    def get_serializer_class(self):
        if self.request.method == "POST":
            return DriverRegisterSerializer
        return super().get_serializer_class()


class DriverRetriever(RetrieveUpdateDestroyAPIView):
    """
    The Retriever for the Driver class

    Args:
        generics (RetrieveUpdateDestroyAPIView): Concrete view for retrieving,
        updating or deleting a model instance.
    """

    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    authentication_classes = [TokenAuthentication]

    def get_permissions(self):
        if self.request.method == "GET":
            self.permission_classes = [AllowAny]
        else:
            self.permission_classes = [IsAuthenticated]
        return super().get_permissions()

    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.id != request.user.id:
            return Response(
                data={"error": "You can only delete your own user account."},
                status=HTTP_403_FORBIDDEN,
            )

        routes = Route.objects.filter(passengers=instance)
        for route in routes:
            route.passengers.remove(instance)

        return super().delete(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.id != request.user.id:
            return Response(
                data={"error": "You can only update your own user account."},
                status=HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)


class UserRetriever(RetrieveUpdateDestroyAPIView):
    """
    The Retriever for the User class

    Args:
        generics (RetrieveUpdateDestroyAPIView): Concrete view for retrieving,
        updating or deleting a model instance.
    """

    queryset = User.objects.all()
    serializer_class = UserSerializer
    # parser_classes = (FormParser, MultiPartParser)

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.id != request.user.id:
            return Response(
                data={"error": "You can only delete your own user account."},
                status=HTTP_403_FORBIDDEN,
            )
        routes = Route.objects.filter(passengers=instance)
        for route in routes:
            route.passengers.remove(instance)
        return super().delete(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.id != request.user.id:
            return Response(
                data={"error": "You can only update your own user account."},
                status=HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)


class ReportListCreate(ListCreateAPIView):
    """
    The class that will generate a list of all the reports and create if needed

    Args:
        generics (ListAPIView): This generates a list of users and pass it as json for the response
    """

    queryset = Report.objects.all()
    serializer_class = ReportSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class ReportRetriever(RetrieveUpdateDestroyAPIView):
    """
    The Retriever for the Report class

    Args:
        generics (RetrieveUpdateDestroyAPIView): Concrete view for retrieving,
        updating or deleting a model instance.
    """

    queryset = Report.objects.all()
    serializer_class = ReportSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.reporter.id != request.user.id:
            return Response(
                data={"error": "You can only delete your own report."},
                status=HTTP_403_FORBIDDEN,
            )
        return super().delete(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Check if the user requesting the action is the same as the user object being retrieved
        if instance.reporter.id != request.user.id:
            return Response(
                data={"error": "You can only update your own report."},
                status=HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)


class UserIdRetriever(GenericAPIView):
    """
    The class for retrieving the user id from the request

    Args:
        generics (GenericAPIView): Generic view for retrieving the user id.
    """

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get(self, request, *args, **kwargs):
        """
        Retrieves the user id from the request.

        Args:
            request (HttpRequest): The request object

        Returns:
            Response: The user id
        """
        user_id = request.user.id
        return Response(data={"user_id": user_id}, status=HTTP_200_OK)


class ValuationListCreate(CreateAPIView):
    """
    The class that will generate a list of all the valuations and create if needed

    Args:
        generics (ListAPIView): This generates a list of users and pass it as json for the response
    """

    queryset = Valuation.objects.all()
    serializer_class = ValuationRegisterSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]


class MyValuationList(ListAPIView):
    """
    The class that will generate all the valuations of the user logged in

    Args:
        generics (ListAPIView): This generates a list of users and pass it as json for the response
    """

    serializer_class = ValuationSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Valuation.objects.filter(receiver=self.request.user)


class UserValuationList(ListAPIView):
    """
    The class that will generate all the valuations of a user

    Args:
        generics (ListAPIView): This generates a list of users and pass it as json for the response
    """

    serializer_class = ValuationSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = get_object_or_404(User, pk=self.kwargs["user_id"])
        return Valuation.objects.filter(receiver=user)


class RegisterFCMToken(APIView):
    """
    The class that will register the FCM token of the user

    Args:
        CreateAPIView: This creates a new FCM token and pass it as json for the response
    """

    serializer_class = FCMTokenSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        request_body=FCMTokenSerializer,
        operation_summary="Register a FCM token for a user",
        operation_description="Register a FCM token for a user",
        responses={201: "Created", 400: "Bad Request", 403: "Forbidden"},
    )
    def post(self, request, *args, **kwargs):
        user = get_object_or_404(User, pk=kwargs["pk"])

        serializer = self.serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)

        token: str = serializer.validated_data.get("token")  # type: ignore
        try:
            # Retrieve the fcm token
            pushController.addToken(user, token)
        except FirebaseError as e:
            if isinstance(e.http_response, Response):
                return e.http_response
            return Response(
                data={"error": e.cause},
                status=HTTP_500_INTERNAL_SERVER_ERROR,
            )
        return Response(status=HTTP_201_CREATED)


class SendFCMNotification(APIView):
    """
    The class that will send a FCM notification to a user

    Args:
        CreateAPIView: This creates a new FCM notification and pass it as json for the response
    """

    serializer_class = FCMessageSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [
        IsAuthenticated,
        # IsAdminUser,
    ]

    @swagger_auto_schema(
        request_body=FCMessageSerializer,
        operation_summary="Send a FCM notification to a user",
        operation_description="Send a FCM notification to a user",
        responses={201: "Sent", 400: "Bad Request", 403: "Forbidden"},
    )
    def post(self, request, pk):
        user = get_object_or_404(User, pk=pk)

        serializer = self.serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        # Check if user has a device token
        token = pushController.token(user)
        if token is None:
            return Response(
                data={"error": "User does not have a device token"},
                status=HTTP_403_FORBIDDEN,
            )
        valid = serializer.validated_data
        priority: str = valid.get("priority", "normal")  # type: ignore
        title: str = valid.get("title")  # type: ignore
        body: str = valid.get("body")  # type: ignore

        try:
            pushController.notifyTo(
                user, title, body, PushController.FCMPriority(priority))
        except FirebaseError as e:
            return Response(data={"error": "Error sending the FCM notification"}, status=e.code)
        return Response(status=HTTP_201_CREATED)


class DriverToUser(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [TokenAuthentication]

    def post(self, request):
        try:
            driver = get_object_or_404(Driver, id=request.user.id)
            achivements = UserAchievementProgress.objects.filter(
                user=request.user
            )
            vector_achivements_data = []
            for achivement in achivements:
                vector_achivements_data.append(model_to_dict(achivement))

            driver_data = {
                "dni": driver.dni,
                "driverPoints": driver.driverPoints,
                "autonomy": driver.autonomy,
                "chargerTypes": list(driver.chargerTypes.all()),
                "preference": driver.preference,
                "iban": driver.iban,
                "profileImage": driver.profileImage,
                "createdAt": driver.createdAt,
                "birthDate": driver.birthDate,
                "points": driver.points,
                "password": driver.password,
                "typeOfLogin": driver.typeOfLogin,
            }
            driver.delete()

            # Recreate the user with the same ID (ID is not changed)
            user = User.objects.create(
                id=request.user.id,
                username=request.user.username,
                first_name=request.user.first_name,
                last_name=request.user.last_name,
                password=driver_data.get("password", "0"),
                email=request.user.email,
                birthDate=driver_data["birthDate"],
                points=driver_data["points"],
                profileImage=driver_data["profileImage"],
                createdAt=driver_data["createdAt"],
                typeOfLogin=driver_data.get("typeOfLogin", "base"),
            )
            achivements = UserAchievementProgress.objects.filter(user=user)

            i = 0
            for achivement in achivements:
                achivement.date_achieved = vector_achivements_data[i]["date_achieved"]
                achivement.progress = vector_achivements_data[i]["progress"]
                achivement.achieved = vector_achivements_data[i]["achieved"]
                achivement.save()
                i += 1

            serialaizer = UserSerializer(user)

            return Response(serialaizer.data, status=HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)


class UserToDriver(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [TokenAuthentication]
    serializer_class = UserToDriverSerializer

    def post(self, request):
        try:
            user = get_object_or_404(User, id=request.user.id)
            data = request.data

            charger_types = data.get("chargerTypes", [])

            preferences = data.get("preferences", {})
            preferenceInstance = Preference.objects.create()
            preferenceInstance.canNotTravelWithPets = preferences.get(
                "canNotTravelWithPets", False)
            preferenceInstance.listenToMusic = preferences.get(
                "listenToMusic", False)
            preferenceInstance.noSmoking = preferences.get("noSmoking", False)
            preferenceInstance.talkTooMuch = preferences.get(
                "talkTooMuch", False)
            preferenceInstance.save()

            driver = Driver.objects.create(
                id=request.user.id,
                username=user.username,
                first_name=user.first_name,
                last_name=user.last_name,
                email=user.email,
                password=user.password,
                birthDate=user.birthDate,
                points=user.points,
                profileImage=user.profileImage,
                createdAt=user.createdAt,
                typeOfLogin=user.typeOfLogin,
                dni=data["dni"],
                driverPoints=data.get("driverPoints", 0),
                autonomy=data.get("autonomy", 0),
                iban=data.get("iban", ""),

            )
            driver.chargerTypes.set(charger_types)
            driver.preference = preferenceInstance  # type: ignore
            driver.save()
            print("driver saved")

            return Response({"message": "You are now a driver."}, status=HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)


class Logout(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [TokenAuthentication]

    def post(self, request):
        try:
            logout(request)
            return Response({"message": "You are now logged out."}, status=HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=HTTP_400_BAD_REQUEST)

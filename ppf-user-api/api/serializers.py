"""
This document contains all the serializers that will be used by the api
"""

from os import write

from common.models.route import Route
from common.models.user import ChargerType, Driver, Preference, Report, User
from common.models.valuation import Valuation
from django.db import models
from django.forms import ChoiceField
from rest_framework.serializers import (
    CharField,
    ChoiceField,
    IntegerField,
    ModelSerializer,
    Serializer,
    ValidationError,
)


class UserSerializer(ModelSerializer):
    """
    The User serializer class

    Args:
        serializers (ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    password2 = CharField(max_length=50, write_only=True, required=False)

    class Meta:
        """
        The Meta definition for user
        """

        model = User
        fields = [
            "id",
            "username",
            "first_name",
            "last_name",
            "email",
            "points",
            "password",
            "password2",
            "birthDate",
            "profileImage",
        ]
        extra_kwargs = {
            "points": {"read_only": True},
            "email": {"read_only": True},
            "password": {
                "write_only": True,
                "required": False,
            },
            "password2": {
                "write_only": True,
                "required": False,
            },
            "username": {"required": False},
            "birthDate": {"required": False},
        }

    def validate(self, attrs):
        password = attrs.get("password", None)
        password2 = attrs.get("password2", None)
        if password and not password2:
            raise ValidationError(
                {"password2": "This field is required when you fill the password."}
            )
        if password2 and not password:
            raise ValidationError(
                {"password": "This field is required when you fill the password2."}
            )
        if password != password2:
            raise ValidationError({"password": "Passwords must match."})
        return super().validate(attrs)

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        if password:
            instance.set_password(password)
        return super().update(instance, validated_data)


class UserImageUpdateSerializer(ModelSerializer):
    """
    The User serializer class

    Args:
        serializers (ModelSerializer): a serializer model to conveniently manipulate the class
    """

    class Meta:
        """
        The Meta definition for user
        """

        model = User
        fields = ["profileImage"]
        extra_kwargs = {
            "profileImage": {"required": True},
        }

    def update(self, instance, validated_data):
        profileImage = validated_data.pop("profileImage")
        instance.profileImage = profileImage
        instance.save()
        return instance


class UserRegisterSerializer(ModelSerializer):
    """
    This is the Serializer for user registration

    Args:
        serializers(ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    password2 = CharField(max_length=50, write_only=True)
    # profileImage = serializers.ImageField(use_url=True)

    class Meta:
        """
        The Meta definition for user
        """

        model = User
        fields = [
            "id",
            "username",
            "first_name",
            "last_name",
            "email",
            "birthDate",
            "password",
            "password2",
            "typeOfLogin",
        ]
        extra_kwargs = {
            "password": {"write_only": True},
            "points": {"write_only": True},
            "id": {"read_only": True},
        }

    def validate(self, attrs):
        password = attrs.get("password")
        password2 = attrs.get("password2")
        if password != password2:
            raise ValidationError("Passwords must match.")

        if User.objects.filter(email=attrs.get("email")).exists():
            raise ValidationError("Email already exists.")

        for field_name, value in attrs.items():
            # Check if the field is not a DateField or DateTimeField
            if not isinstance(value, (models.DateField, models.DateTimeField)):
                if not isinstance(value, str):
                    continue  # Skip validation if value is not a string

                if not value.strip():  # Check if value is a blank string
                    raise ValidationError(
                        f"{field_name.capitalize()} cannot be blank.")
        return attrs

    def create(self, validated_data):
        validated_data.pop("password2")  # Remove password2 from saving
        password = validated_data.pop("password")
        user = User.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user


class ChargerTypeSerializer(ModelSerializer):
    class Meta:
        model = ChargerType
        fields = "__all__"


class PreferenceSerializer(ModelSerializer):
    class Meta:
        model = Preference
        fields = "__all__"


class DriverSerializer(UserSerializer):
    """
    The Driver serializer class

    Args:
        serializers(ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    preference = PreferenceSerializer(required=False)

    class Meta:
        """
        The Meta definition for Driver
        """

        model = Driver
        fields = UserSerializer.Meta.fields + [
            "driverPoints",
            "autonomy",
            "chargerTypes",
            "preference",
            "iban",
        ]

        extra_kwargs = UserSerializer.Meta.extra_kwargs.copy()
        extra_kwargs.update(
            {
                "chargerTypes": {"required": False},
                "driverPoints": {"read_only": True},
            }
        )

    def validate(self, attrs):
        return super().validate(attrs)

    def update(self, instance, validated_data):
        chargerTypesData = validated_data.pop("chargerTypes", None)
        if chargerTypesData is not None:
            # Delete all the previous relations
            instance.chargerTypes.clear()
            # Add new relations
            for chargerTypeData in chargerTypesData:
                chargerType = ChargerType.objects.get(
                    chargerType=chargerTypeData)
                instance.chargerTypes.add(chargerType)

        preferenceData = validated_data.pop("preference", None)
        if preferenceData is not None:
            # Update preference fields
            preference = instance.preference
            preference.canNotTravelWithPets = preferenceData.get(
                "canNotTravelWithPets", preference.canNotTravelWithPets
            )
            preference.listenToMusic = preferenceData.get(
                "listenToMusic", preference.listenToMusic)
            preference.noSmoking = preferenceData.get(
                "noSmoking", preference.noSmoking)
            preference.talkTooMuch = preferenceData.get(
                "talkTooMuch", preference.talkTooMuch)
            preference.save()

        return super().update(instance, validated_data)


class DriverRegisterSerializer(ModelSerializer):
    """
    This is the Serializer for user registration

    Args:
        serializers(ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    password2 = CharField(max_length=50, write_only=True)
    preference = PreferenceSerializer()

    class Meta:
        """
        The Meta definition for user
        """

        model = Driver
        fields = [
            "id",
            "username",
            "first_name",
            "last_name",
            "email",
            "birthDate",
            "password",
            "password2",
            "dni",
            "autonomy",
            "chargerTypes",
            "preference",
            "iban",
            "profileImage",
        ]
        extra_kwargs = {
            "password": {"write_only": True, "required": True},
            "driverPoints": {"read_only": True},
            "id": {"read_only": True},
        }

    def validate(self, attrs):
        password = attrs.get("password")
        password2 = attrs.get("password2")
        if password != password2:
            raise ValidationError("Passwords must match.")
        if User.objects.filter(email=attrs.get("email")).exists():
            raise ValidationError("Email already exists.")
        for field_name, value in attrs.items():
            # Check if the field is not a DateField or DateTimeField
            if not isinstance(value, (models.DateField, models.DateTimeField)):
                if not isinstance(value, str):
                    continue  # Skip validation if value is not a string

                if not value.strip():  # Check if value is a blank string
                    raise ValidationError(
                        f"{field_name.capitalize()} cannot be blank.")
        return attrs

    def create(self, validated_data):
        validated_data.pop("password2")  # Remove password2 from saving
        password = validated_data.pop("password")
        preferenceData = validated_data.pop("preference")
        chargerTypesData = validated_data.pop("chargerTypes", None)

        preference = Preference.objects.create(**preferenceData)

        driver = Driver.objects.create_user(
            **validated_data, preference=preference)
        driver.set_password(password)
        driver.save()

        if chargerTypesData:
            for chargerTypeData in chargerTypesData:
                chargerType = ChargerType.objects.get(
                    chargerType=chargerTypeData)
                driver.chargerTypes.add(chargerType)

        return driver


class ReportSerializer(ModelSerializer):
    """
    The reports serializer

    Args:
        serializers(ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    class Meta:
        """
        The Meta definition for report
        """

        model = Report
        fields = "__all__"
        read_only_fields = ["reporter"]  # Set reporter field as read-only

    def create(self, validated_data):
        """
        Override the create method to automatically fill the reporter field with the authenticated user.
        """
        # BUG not a bug but we cant be managing a request object in the serializer, this is a bad practice
        request = self.context.get("request")
        validated_data["reporter"] = (
            User.objects.all().filter(pk=request.user.id).first()  # type: ignore
        )
        return super().create(validated_data)


class ValuationSerializer(ModelSerializer):
    """
    The Valuation serializer class

    Args:
        serializers(ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    class Meta:
        """
        The Meta definition for Valuation
        """

        model = Valuation
        fields = ["id", "giver", "receiver", "rating", "comment"]


class ValuationRegisterSerializer(ModelSerializer):
    """
    This is the Serializer for valuation creation

    Args:
        serializers(ModelSerializer): a serializer model to conveniently manipulate the class
        and create the JSON
    """

    receiver = IntegerField(source="receiver.id")

    class Meta:
        model = Valuation
        fields = ["receiver", "route", "rating", "comment"]
        extra_kwargs = {
            "comment": {"required": False},
        }

    def validate(self, attrs):
        receiverId = attrs.get("receiver").get("id")
        giver = self.context["request"].user

        if not User.objects.filter(pk=receiverId).exists():
            raise ValidationError(
                {"error": "Invalid receiver ID. User not found."})

        receiver = User.objects.get(pk=receiverId)

        if receiver.pk == giver.pk:
            raise ValidationError({"error": "You cannot rate yourself."})

        route_id = attrs["route"].pk
        if not (
            Route.objects.filter(driver=receiver, pk=route_id).exists()
            or Route.objects.filter(passengers=receiver, pk=route_id).exists()
        ):
            raise ValidationError(
                {"error": "The receiver is not part of the route."})

        # The giver, i.e the authificated user, belongs to the route
        if not (
            Route.objects.filter(driver=giver, pk=route_id).exists()
            or Route.objects.filter(passengers=giver, pk=route_id).exists()
        ):
            raise ValidationError(
                {"error": "The giver is not part of the route."})

        if (
            Route.objects.filter(passengers=giver, pk=route_id).exists()
            and Route.objects.filter(passengers=receiver, pk=route_id).exists()
        ):
            raise ValidationError(
                {"error": "A passenger cannot value other passengers."})

        if Valuation.objects.filter(giver=giver, receiver=receiver, route_id=route_id).exists():
            raise ValidationError(
                {"error": "You have already rated this user in this route."})

        return attrs

    def create(self, validated_data):
        receiver_id = validated_data.get("receiver").get("id")
        route = validated_data.get("route")
        rating = validated_data.get("rating")
        comment = validated_data.get("comment")
        giver_id = self.context["request"].user.id

        try:
            valuation = Valuation.objects.create(
                giver_id=giver_id,
                receiver_id=receiver_id,
                route=route,
                rating=rating,
                comment=comment,
            )
        except Exception as e:
            raise ValidationError({"error": str(e)})

        return valuation


class FCMTokenSerializer(Serializer):
    token = CharField(max_length=255)

    def validate_token(self, value):
        if not value:
            raise ValidationError("Token cannot be empty")
        return value


class FCMessageSerializer(Serializer):
    title = CharField(max_length=255)
    body = CharField(max_length=255)
    priority = ChoiceField(choices=["normal", "high"], required=False)


class UserToDriverSerializer(Serializer):
    dni = CharField(max_length=9)
    iban = CharField(max_length=34)
    autonomy = IntegerField()
    preferences = PreferenceSerializer()
    chargerTypes = ChargerTypeSerializer(many=True)
    driverPoints = IntegerField()

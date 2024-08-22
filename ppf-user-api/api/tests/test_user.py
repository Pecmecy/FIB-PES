"""
This module contains the tests for the users.
"""

from rest_framework.reverse import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from common.models import achievement
from common.models.user import User, ChargerType, Driver, Preference
from common.models.achievement import UserAchievementProgress

import json

from rest_framework.authtoken.models import Token


class CreateUserTest(APITestCase):
    """
    Test Create User
    """

    def setUp(self):
        self.userFail = User.objects.create(
            username="failUser",
            birthDate="1998-10-06",
            password="failUser",
            email="failUser@gmail.com",
        )

    def testSuccessfulCreateUser(self):
        """
        Ensure the API call creates a user in the database.
        """

        username = "test"
        birthDate = "1998-10-06"
        password = "test"
        password2 = "test"
        email = "test@gmail.com"

        url = reverse("userListCreate")
        data = {
            "username": username,
            "birthDate": birthDate,
            "password": password,
            "password2": password2,
            "email": email,
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user_exists = User.objects.filter(username=username).exists()
        self.assertTrue(user_exists)

        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("username"), username)
        self.assertEqual(message.get("birthDate"), birthDate)
        self.assertEqual(message.get("email"), email)

    def testUserExists(self):
        """
        Ensure the API call returns an error if the user already exists.
        """

        username = "failUser"
        birthDate = "1998-10-06"
        password = "failUser"
        password2 = "failUser"
        email = "failUser@gmail.com"

        url = reverse("userListCreate")
        data = {
            "username": username,
            "birthDate": birthDate,
            "password": password,
            "password2": password2,
            "email": "distintUser@gmail.com",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("A user with that username already exists.", message.get("username"))

        url = reverse("userListCreate")
        data = {
            "username": "distintUser",
            "birthDate": birthDate,
            "password": password,
            "password2": password2,
            "email": email,
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("Email already exists.", message.get("non_field_errors"))

    def testIncorrectPassword(self):
        """
        Ensure the API call returns an error if the password is incorrect.
        """

        url = reverse("userListCreate")
        data = {
            "username": "distintUser",
            "birthDate": "1998-10-06",
            "password": "distintUser",
            "password2": "distintUser2",
            "email": "distintUser@gmail.com",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        message = json.loads(response.content.decode("utf-8"))
        self.assertIn("Passwords must match.", message.get("non_field_errors"))

    def testPointsCannotBeSet(self):
        """
        Ensure the API call returns an error if the points are set.
        """

        url = reverse("userListCreate")
        data = {
            "username": "distintUser",
            "birthDate": "1998-10-06",
            "password": "distintUser",
            "password2": "distintUser",
            "email": "distintUser@gmail.com",
            "points": 100,
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        userCreated = User.objects.get(username="distintUser")
        token, _ = Token.objects.get_or_create(user=userCreated)

        urlGet = reverse("userRetriever", kwargs={"pk": userCreated.pk})
        headers = {
            "Authorization": f"Token {token}",
        }
        responseGet = self.client.get(urlGet, headers=headers)  # type: ignore
        self.assertEqual(responseGet.status_code, status.HTTP_200_OK)
        messageGet = json.loads(responseGet.content.decode("utf-8"))
        self.assertEqual(messageGet.get("points"), 0)


class ListUserTest(APITestCase):
    """
    Test List User
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.user2 = User.objects.create(
            username="test2", birthDate="1998-10-06", password="test2", email="test2@gmail.com"
        )
        self.user3 = User.objects.create(
            username="test3", birthDate="1998-10-06", password="test3", email="test3@gmail.com"
        )

    def testSuccessfulListUser(self):
        """
        Ensure the API call returns a list of users.
        """

        url = reverse("userListCreate")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))

        # Check the number of users returned
        self.assertEqual(len(message), 3)

        # Check the details of the first user
        self.assertEqual(message[0].get("id"), self.user.pk)
        self.assertEqual(message[0].get("username"), self.user.username)
        self.assertEqual(message[0].get("first_name"), self.user.first_name)
        self.assertEqual(message[0].get("last_name"), self.user.last_name)
        self.assertEqual(message[0].get("birthDate"), self.user.birthDate)
        self.assertEqual(message[0].get("email"), self.user.email)
        self.assertEqual(message[0].get("points"), self.user.points)

        # Check the details of the second user
        self.assertEqual(message[1].get("id"), self.user2.pk)
        self.assertEqual(message[1].get("username"), self.user2.username)
        self.assertEqual(message[1].get("first_name"), self.user2.first_name)
        self.assertEqual(message[1].get("last_name"), self.user2.last_name)
        self.assertEqual(message[1].get("birthDate"), self.user2.birthDate)
        self.assertEqual(message[1].get("email"), self.user2.email)
        self.assertEqual(message[1].get("points"), self.user2.points)

        # Check the details of the third user
        self.assertEqual(message[2].get("id"), self.user3.pk)
        self.assertEqual(message[2].get("username"), self.user3.username)
        self.assertEqual(message[2].get("first_name"), self.user3.first_name)
        self.assertEqual(message[2].get("last_name"), self.user3.last_name)
        self.assertEqual(message[2].get("birthDate"), self.user3.birthDate)
        self.assertEqual(message[2].get("email"), self.user3.email)
        self.assertEqual(message[2].get("points"), self.user3.points)


class GetUserTest(APITestCase):
    """
    Test Get User
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.token, _ = Token.objects.get_or_create(user=self.user)

    def testSuccessfulGetUser(self):
        """
        Ensure the API call returns the user information.
        """

        url = reverse("userRetriever", kwargs={"pk": self.user.pk})
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.get(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("id"), self.user.pk)
        self.assertEqual(message.get("username"), self.user.username)
        self.assertEqual(message.get("first_name"), self.user.first_name)
        self.assertEqual(message.get("last_name"), self.user.last_name)
        self.assertEqual(message.get("birthDate"), self.user.birthDate)
        self.assertEqual(message.get("email"), self.user.email)
        self.assertEqual(message.get("points"), self.user.points)

    def testUnauthorizedGetUser(self):
        """
        Ensure the API call returns an error if the user is not authenticated.
        """

        url = reverse("userRetriever", kwargs={"pk": self.user.pk})
        response = self.client.get(url)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Authentication credentials were not provided.")

    def testUserNotExists(self):
        """
        Ensure the API call returns an error if the user does not exist.
        """

        url = reverse("userRetriever", kwargs={"pk": 1000})
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.get(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Not found.")


class UpdateUserTest(APITestCase):
    """
    Test Update User
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.token, _ = Token.objects.get_or_create(user=self.user)

    def testSuccessfulUpdateUser(self):
        """
        Ensure the API call updates the user information.
        """

        url = reverse("userRetriever", kwargs={"pk": self.user.pk})
        dataPut = {
            "username": "newUsername",
            "first_name": "newFirstName",
            "last_name": "newLastName",
            "birthDate": "2000-10-06",
            "email": "newUsername@gmail.com",
        }
        headers = {
            "Authorization": f"Token {self.token}",
        }
        # Complete PUT
        response = self.client.put(url, dataPut, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("id"), self.user.pk)
        self.assertEqual(message.get("username"), "newUsername")
        self.assertEqual(message.get("first_name"), "newFirstName")
        self.assertEqual(message.get("last_name"), "newLastName")
        self.assertEqual(message.get("birthDate"), "2000-10-06")
        self.assertEqual(message.get("email"), self.user.email)

        # Partial PUT
        dataPut2 = {"username": "newUsername2"}
        response = self.client.put(url, dataPut2, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("id"), self.user.pk)
        self.assertEqual(message.get("username"), "newUsername2")
        self.assertEqual(message.get("first_name"), "newFirstName")  # Previous updated value
        self.assertEqual(message.get("last_name"), "newLastName")  # Previous updated value
        self.assertEqual(message.get("birthDate"), "2000-10-06")  # Previous updated value
        self.assertEqual(message.get("email"), self.user.email)

        # Partial PATCH
        dataPatch = {
            "username": "newUsername",
        }
        response = self.client.patch(url, dataPatch, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("id"), self.user.pk)
        self.assertEqual(message.get("username"), "newUsername")
        self.assertEqual(message.get("first_name"), "newFirstName")  # Previous updated value
        self.assertEqual(message.get("last_name"), "newLastName")  # Previous updated value
        self.assertEqual(message.get("birthDate"), "2000-10-06")  # Previous updated value
        self.assertEqual(message.get("email"), self.user.email)

        # Complete PATCH
        dataPatch2 = {
            "username": "newUsername2",
            "first_name": "newFirstName2",
            "last_name": "newLastName2",
            "birthDate": "1998-10-06",
            "email": "newUsername2@gmail.com",
        }
        response = self.client.patch(url, dataPatch2, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("id"), self.user.pk)
        self.assertEqual(message.get("username"), "newUsername2")
        self.assertEqual(message.get("first_name"), "newFirstName2")
        self.assertEqual(message.get("last_name"), "newLastName2")
        self.assertEqual(message.get("birthDate"), "1998-10-06")
        self.assertEqual(message.get("email"), self.user.email)

    def testEmailCannotBeUpdated(self):
        """
        Ensure the API call returns an error if the user tries to update the email.
        """

        url = reverse("userRetriever", kwargs={"pk": self.user.pk})
        data = {"email": "perdigon@gmail.com"}
        headers = {
            "Authorization": f"Token {self.token}",
        }
        responsePut = self.client.put(url, data, headers=headers)  # type: ignore
        self.assertEqual(responsePut.status_code, status.HTTP_200_OK)
        message = json.loads(responsePut.content.decode("utf-8"))
        self.assertEqual(message.get("email"), self.user.email)
        self.assertNotEqual(message.get("email"), "perdigon@gmail.com")

    def testUnauthorizedUpdateUser(self):
        """
        Ensure the API call returns an error if the user is not authenticated.
        """

        url = reverse("userRetriever", kwargs={"pk": self.user.pk})
        data = {"username": "newUsername"}
        responsePut = self.client.put(url, data)
        self.assertEqual(responsePut.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(responsePut.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Authentication credentials were not provided.")

        responsePatch = self.client.put(url, data)
        self.assertEqual(responsePatch.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(responsePatch.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Authentication credentials were not provided.")

    def testUserNotExists(self):
        """
        Ensure the API call returns an error if the user does not exist.
        """

        url = reverse("userRetriever", kwargs={"pk": 1000})
        data = {"username": "newUsername"}
        headers = {
            "Authorization": f"Token {self.token}",
        }
        responsePut = self.client.put(url, data, headers=headers)  # type: ignore
        self.assertEqual(responsePut.status_code, status.HTTP_404_NOT_FOUND)
        message = json.loads(responsePut.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Not found.")

        responsePatch = self.client.patch(url, data, headers=headers)  # type: ignore
        self.assertEqual(responsePatch.status_code, status.HTTP_404_NOT_FOUND)
        message = json.loads(responsePatch.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Not found.")

    def testUserCannotUpdateOtherUser(self):
        """
        Ensure the API call returns an error if the user tries to update another user.
        """

        user2 = User.objects.create(
            username="test2", birthDate="1998-10-06", password="test2", email="test2@gmail.com"
        )
        url = reverse("userRetriever", kwargs={"pk": user2.pk})
        data = {"username": "newUsername"}
        headers = {"Authorization": f"Token {self.token}"}
        responsePut = self.client.put(url, data, headers=headers)  # type: ignore
        self.assertEqual(responsePut.status_code, status.HTTP_403_FORBIDDEN)
        message = json.loads(responsePut.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "You can only update your own user account.")

        responsePatch = self.client.patch(url, data, headers=headers)  # type: ignore
        self.assertEqual(responsePatch.status_code, status.HTTP_403_FORBIDDEN)
        message = json.loads(responsePatch.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "You can only update your own user account.")


class DeleteUserTest(APITestCase):
    """
    Test Delete User
    """

    def testSuccessfulDeleteUser(self):
        """
        Ensure the API call deletes the user.
        """
        user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        token, _ = Token.objects.get_or_create(user=user)

        url = reverse("userRetriever", kwargs={"pk": user.pk})
        headers = {
            "Authorization": f"Token {token}",
        }
        response = self.client.delete(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

    def testUnauthorizedDeleteUser(self):
        """
        Ensure the API call returns an error if the user is not authenticated.
        """
        user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )

        url = reverse("userRetriever", kwargs={"pk": user.pk})
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Authentication credentials were not provided.")

    def testUserWhoDeleteNotExists(self):
        """
        Ensure the API call returns an error if the user does not exist.
        """
        user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        token, _ = Token.objects.get_or_create(user=user)

        url = reverse("userRetriever", kwargs={"pk": 1000})
        headers = {
            "Authorization": f"Token {token}",
        }
        response = self.client.delete(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Not found.")

    def testUserDeletedNotExists(self):
        """
        Ensure the API call returns an error if the user does not exist.
        """
        user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        token, _ = Token.objects.get_or_create(user=user)

        url = reverse("userRetriever", kwargs={"pk": 1000})
        headers = {
            "Authorization": f"Token {token}",
        }
        response = self.client.delete(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Not found.")

    def testUserCannotDeleteOtherUser(self):
        """
        Ensure the API call returns an error if the user tries to delete another user.
        """
        user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        token, _ = Token.objects.get_or_create(user=user)
        user2 = User.objects.create(
            username="test2", birthDate="1998-10-06", password="test2", email="test2@gmail.com"
        )

        url = reverse("userRetriever", kwargs={"pk": user2.pk})
        headers = {
            "Authorization": f"Token {token}",
        }
        response = self.client.delete(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("error"), "You can only delete your own user account.")


class GetSelfIDTest(APITestCase):
    """
    Test Get Self ID
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.token, _ = Token.objects.get_or_create(user=self.user)

    def testSuccessfulGetSelfID(self):
        """
        Ensure the API call returns the user information.
        """

        url = reverse("userIdRetriever")
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.get(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("user_id"), self.user.pk)

    def testUserNotExists(self):
        """
        Ensure the API call returns an error if the user does not exist.
        """

        url = reverse("userIdRetriever")
        headers = {
            "Authorization": f"Token Bonito",
        }
        response = self.client.get(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Invalid token.")

    def testUnauthorizedGetSelfID(self):
        """
        Ensure the API call returns an error if the user is not authenticated.
        """

        url = reverse("userIdRetriever")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        message = json.loads(response.content.decode("utf-8"))
        self.assertEqual(message.get("detail"), "Authentication credentials were not provided.")


class UserToDriverTest(APITestCase):
    """
    Test User To Driver
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.token, _ = Token.objects.get_or_create(user=self.user)

    def testSuccessfulUserToDriver(self):
        """
        Ensure the API call updates the user information.
        """

        url = reverse("userToDriver")
        data = {"dni": "E210283822"}
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, data, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)


class DriverToUserTest(APITestCase):
    """
    Test Driver To User
    """

    def testSuccessfulDriverToUser(self):
        """
        Ensure the API call updates the user information.
        """
        mennekes = ChargerType.objects.create(chargerType="Mennekes")
        tesla = ChargerType.objects.create(chargerType="Tesla")
        driver = Driver.objects.create(
            username="driver1",
            birthDate="1998-10-06",
            email="driver@gmail.com",
            password="driver",
            dni="12345678",
            preference=Preference.objects.create(),
            iban="ES662100999",
        )
        driver.chargerTypes.set(
            [mennekes, tesla]
        )
        token, _ = Token.objects.get_or_create(user=driver)

        url = reverse("driverToUser")
        headers = {
            "Authorization": f"Token {token}",
        }
        response = self.client.post(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)


class LogoutTest(APITestCase):
    """
    Test Logout
    """

    def setUp(self):
        self.user = User.objects.create(
            username="test", birthDate="1998-10-06", password="test", email="test@gmail.com"
        )
        self.token, _ = Token.objects.get_or_create(user=self.user)

    def testSuccessfulLogout(self):
        """
        Ensure the API call logs out the user.
        """

        url = reverse("logout")
        headers = {
            "Authorization": f"Token {self.token}",
        }
        response = self.client.post(url, headers=headers)  # type: ignore
        self.assertEqual(response.status_code, status.HTTP_200_OK)

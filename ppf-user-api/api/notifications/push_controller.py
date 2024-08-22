from email import message
from enum import Enum
from venv import logger

from common.models.fcm import FCMToken
from common.models.user import User
from firebase_admin.exceptions import FirebaseError
from firebase_admin.messaging import AndroidConfig, Message, Notification, send


class PushController:
    tokens = FCMToken.objects

    class FCMPriority(Enum):
        HIGH = "high"
        NORMAL = "normal"

    def token(self, user: User):
        """
        - user: The user to get the token for
        """
        return self.tokens.filter(user=user).first()

    def addToken(self, user: User, token: str):
        """
        - user: The user to associate the token with
        - token: The token to associate with the user

        rise
        """
        FCMToken.objects.filter(user=user).delete()
        t = FCMToken(user=user, token=token)
        message = Message(
            token=t.token,
            notification=Notification(title="Validity check"),
            android=AndroidConfig(priority="high"),
        )
        send(
            message,
            True,
        )
        # Only saved if no exception is raised
        t.save()

    def notifyTo(
        self, user: User, title: str, body: str, priority: FCMPriority = FCMPriority.NORMAL
    ) -> str:
        """
        - user: The user to send the push notification
        - title: The title of the notification
        - body: The body of the notification
        - priority: The priority of the notification either high or normal
        """
        t = self.tokens.filter(user=user)
        try:
            return send(
                Message(
                    token=t,
                    notification=Notification(title=title, body=body),
                    android=AndroidConfig(priority=priority.value),
                ),
            )
        except FirebaseError | ValueError as e:
            logger.error(f"Failed to send notification {e}")
            return ""

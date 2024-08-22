from rest_framework.generics import ListAPIView
from common.models.achievement import UserAchievementProgress
from achievement.serializers import UserAchievementProgressSerializer
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication


class MyAchievementList(ListAPIView):
    """
    List all my achievements.
    """

    serializer_class = UserAchievementProgressSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserAchievementProgress.objects.filter(user=self.request.user)


class UserAchievementList(ListAPIView):
    """
    List all achievements of a user.
    """

    serializer_class = UserAchievementProgressSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.kwargs["id"]
        return UserAchievementProgress.objects.filter(user_id=user_id)

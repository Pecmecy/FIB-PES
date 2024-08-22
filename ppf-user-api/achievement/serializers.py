from rest_framework import serializers
from common.models.achievement import UserAchievementProgress


class UserAchievementProgressSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source="achievement.title")

    class Meta:
        model = UserAchievementProgress
        fields = [
            "title",
            "achieved",
            "date_achieved",
        ]

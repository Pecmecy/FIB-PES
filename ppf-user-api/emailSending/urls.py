"""
This file is used to define the URL patterns for the contact app.
"""

from django.urls import path
from . import views

urlpatterns = [
    path("reset-password/", views.PasswordResetRequestView.as_view(), name="passwordReset"),
    path("reset-password/confirm/", views.PasswordResetConfirmView.as_view(), name="setNewPassword"),
    path("reset-password-page/", views.reset_password_page, name="resetPasswordPage"),
]

"""
This document contains all the forms to handle the updates from the admin page
"""
from typing import Any

from common.models import route
from common.models.route import Route
from common.models.user import User
from django import forms


class UserForm(forms.ModelForm):
    """
    A form for updating user information in the admin page.

    Args:
        forms (ModelForm): A form for updating a User model instance.
    """
    class Meta:
        model = User
        fields = '__all__'
        exclude = ['profileImage']


class RouteForm(forms.ModelForm):
    """
    A form for updating route information in the admin page.

    Args:
        forms (ModelForm): A form for updating a Route model instance.
    """

    class Meta:
        model = Route
        fields = '__all__'
        exclude = ['passengers']


class LoginForm(forms.Form):
    username = forms.CharField(max_length=150)
    password = forms.CharField(widget=forms.PasswordInput)

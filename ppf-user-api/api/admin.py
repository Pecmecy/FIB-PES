"""
This document contains all the models that will be registered in the admin panel.
"""

from common.models.user import Driver, User
from django.contrib import admin

# Register your models here.

admin.site.register([User, Driver])

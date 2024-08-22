import json

import requests
from adminPage.forms import LoginForm, RouteForm, UserForm
from common.models.route import Route
from common.models.user import Driver, Report, User
from django.contrib.auth.hashers import make_password
from django.db.models import Count, OuterRef, Q, Subquery
from django.forms import model_to_dict
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from rest_framework.authtoken.models import Token

from .decorators import login_required
from .forms import LoginForm

# create generic functions


def sendDeleteRequest(user, token=None, url=None):
    """
    Sends a DELETE request to the specified URL with the provided token as authorization.

    Parameters:
    user (User): The User object for which the token is retrieved.
    token (Token, optional): The Token object to use for authorization. Defaults to the token associated with the provided user.
    url (str): The URL to send the DELETE request to.

    Raises:
    ValueError: If the URL or token key is not a string.

    Returns:
    requests.Response: The response object from the DELETE request.
    """
    if not token:
        token = Token.objects.get(user=user)

    # Ensure that url is a string
    if not isinstance(url, str):
        raise ValueError(f"url must be a string\nURL: {url}")

    # Ensure that token.key is a string
    if not isinstance(token.key, str):
        raise ValueError("token.key must be a string")

    # Concatenate 'Token ' and token.key
    auth_header = 'Token ' + token.key
    print('request send to ' + url)

    return requests.delete(url=url, headers={'Authorization': auth_header})


def deleteUser(user):
    """
    Deletes the specified user.

    Args:
        user (User): The user object to be deleted.

    Returns:
        requests.Response: The response object from the DELETE request.
    """
    url = 'http://user-api:8000/users/' + str(user.pk)

    return sendDeleteRequest(user, url=url)


def home(request):
    return redirect('users')
    # return render(request, 'views/home.html')


@login_required
def users(request):
    """
    Retrieves all users from the database and filters them based on a search filter provided in the request query string.

    Parameters:
        request (HttpRequest): The HTTP request object.

    Returns:
        HttpResponse: The rendered 'views/users.html' template with the filtered list of users.
    """
    users = User.objects.all()
    search_filter = request.GET.get('searching')

    if search_filter:
        users = users.filter(username__icontains=search_filter)

    return render(request, "views/users.html", {"users": users})


@login_required
def reported(request):
    """
    Displays a list of users who have been reported.

    Parameters:
        request (HttpRequest): The HTTP request object.

    Returns:
        HttpResponse: The rendered reported.html template with a queryset of users who have been reported.

    This function handles the HTTP GET request for the 'reported' endpoint. It retrieves a list of users who have been reported and displays them in the reported.html template. The function first checks if the request method is POST and if the '_method' parameter is set to 'DELETE'. If so, it deletes the specified user and redirects to the 'reports' page. 

    The function then performs a database query to count the number of reports for each user. It uses a subquery to annotate each user queryset with the report count. The queryset is filtered to include only users who have been reported at least once and is ordered by the report count in descending order.

    If a 'searching' parameter is present in the request GET parameters, the queryset is further filtered to include only users whose username contains the search filter.

    Finally, the function renders the reported.html template with the queryset of users who have been reported.

    Note: The reported.html template expects a 'users' variable to be passed to it.

    """

    if request.method == 'POST' and request.POST.get('_method') == 'DELETE':
        userId = request.POST.get('userId')
        user = get_object_or_404(User, pk=userId)
        deleteUser(user)
        return redirect('reports')

    # Subquery to count the number of reports for each user
    report_counts = Report.objects.filter(reported_id=OuterRef('id')).values('reported_id').annotate(
        report_count=Count('id')
    ).values('report_count')

    # Annotate each user queryset with the report count using the subquery
    users = User.objects.annotate(report_count=Subquery(report_counts))

    # Filter users who have been reported at least once
    users = users.filter(report_count__gt=0).order_by('-report_count')

    search_filter = request.GET.get('searching')

    if search_filter:
        users = users.filter(username__icontains=search_filter)

    return render(request, "views/reported.html", {"users": users})


@login_required
def userDetails(request, pk):
    """
    Retrieves and displays details of a user.

    Args:
        request (HttpRequest): The HTTP request object.
        pk (int): The primary key of the user.

    Returns:
        HttpResponse: The rendered user details page.

    Raises:
        Http404: If the user with the given primary key does not exist.

    This function retrieves a user object based on the provided primary key. If the request method is POST and the
    '_method' parameter is set to 'DELETE', the user is deleted and the user is redirected to the 'home' page. Otherwise,
    the function creates a dictionary representation of the user object using the 'model_to_dict' function. If a
    'searching' parameter is provided in the request query string, the function filters the user dictionary to only
    include key-value pairs that contain the search filter in either the key or the value. The filtered dictionary is
    then rendered and returned as the response.
    """
    user = get_object_or_404(User, pk=pk)

    if request.method == 'POST' and request.POST.get('_method') == 'DELETE':
        deleteUser(user)
        return redirect('home')

    user_dict = model_to_dict(user)  # type: ignore

    search_filter = request.GET.get('searching')
    if search_filter:
        searched_dict = {}
        for key, value in user_dict.items():
            if search_filter.lower() in key.lower() or search_filter.lower() in str(value).lower():
                searched_dict[key] = value
            elif user and hasattr(user, key) and str(getattr(user, key)).lower().find(search_filter.lower()) != -1:
                searched_dict[key] = value
        user_dict = searched_dict

    return render(request, 'views/user_details.html', {'user': user, 'user_data': user_dict})


@login_required
def userDetailsEdit(request, pk):
    """
    Updates the details of a user with the given primary key.

    Args:
        request (HttpRequest): The HTTP request object.
        pk (int): The primary key of the user.

    Returns:
        HttpResponse: The rendered user details page if the request method is GET.
                      Redirects to the 'userDetails' page with the updated user's primary key if the request method is POST.

    Raises:
        Http404: If the user with the given primary key does not exist.

    This function retrieves a user object based on the provided primary key. If the request method is POST, it validates
    the form data and updates the user's details. If the password has changed, it sets the new password. The user is then
    saved and a redirect is performed to the 'userDetails' page with the updated user's primary key. If the request method
    is GET, it renders the 'views/user_details_edit.html' template with the user form and the user object.
    """
    user = get_object_or_404(User, pk=pk)

    if request.method == 'POST':
        old_password = user.password
        form = UserForm(request.POST, instance=user)
        if form.is_valid():
            user = form.save(commit=False)
            if (user.password != old_password):
                user.set_password(user.password)
            user.save()
        return redirect('userDetails', pk=pk)
    else:
        form = UserForm(instance=user)

    return render(request, 'views/user_details_edit.html', {'form': form, 'user': user})


@login_required
def userReportsDetails(request, pk):
    """
    Displays a list of reports for the specified user.

    Args:
        request (HttpRequest): The HTTP request object.
        pk (int): The primary key of the user.

    Returns:
        HttpResponse: The rendered user report details page.

    Raises:
        Http404: If the user with the given primary key does not exist.

    This function retrieves a user object based on the provided primary key. If the request method is POST and the
    '_method' parameter is set to 'DELETE', the user is deleted and the user is redirected to the 'userReportsDetails'
    page with the primary key of the user. Otherwise, the function retrieves a list of reports for the user and filters
    them based on a search filter provided in the request query string. The function then renders the
    'views/user_report_details.html' template with the user object, the list of reports, and the count of reports.
    """

    if request.method == 'POST' and request.POST.get('_method') == 'DELETE':
        user = get_object_or_404(User, pk=pk)
        deleteUser(user)
        return redirect('userReportsDetails', pk)

    user = get_object_or_404(User, pk=pk)
    reports = Report.objects.filter(reported_id=pk)
    reports_count = reports.count()

    search_filter = request.GET.get('searching')
    if search_filter:
        user_set = User.objects.filter(username__icontains=search_filter)
        reports = reports.filter(reporter__in=user_set)
    return render(request, 'views/user_report_details.html', {'user': user, 'reports': reports, 'reports_count': reports_count})


@login_required
def reportDetails(request, pk):
    """
    Retrieves a report object based on the provided primary key and displays its details.

    Args:
        request (HttpRequest): The HTTP request object.
        pk (int): The primary key of the report.

    Returns:
        HttpResponse: The rendered report details page if the request method is GET.
                      Redirects to the 'userReportsDetails' page with the reported user's primary key if the request method is POST and the '_method' parameter is set to 'DELETE'.

    Raises:
        Http404: If the report with the given primary key does not exist.

    This function retrieves a report object based on the provided primary key. If the request method is POST and the '_method' parameter is set to 'DELETE', the report is deleted and the user is redirected to the 'userReportsDetails' page with the reported user's primary key. Otherwise, the function renders the 'views/report_details.html' template with the report object.
    """
    report = get_object_or_404(Report, pk=pk)
    if request.method == 'POST' and request.POST.get('_method') == 'DELETE':
        reportedId = str(report.reported.pk)
        report.delete()
        return redirect('userReportsDetails', reportedId)
    return render(request, 'views/report_details.html', {'report': report})


@login_required
def routes(request):
    routes = Route.objects.all()
    if request.method == 'GET':
        if request.GET.get('searching'):
            search_filter = request.GET.get('searching')
            routes = routes.filter(Q(destinationAlias__icontains=search_filter) | Q(
                originAlias__icontains=search_filter))

    return render(request, 'views/routes.html', {'routes': routes})


@login_required
def routeDetails(request, pk):
    route = get_object_or_404(Route, pk=pk)
    route_data = {}
    for key, value in route.__dict__.items():
        if key.startswith('_'):
            continue
        route_data[key] = value
    route_data["passengers"] = route.passengers

    search_filter = request.GET.get('searching')
    if search_filter:
        searched_dict = {}
        for key, value in route_data.items():
            if search_filter.lower() in key.lower() or search_filter.lower() in str(value).lower():
                searched_dict[key] = value
            elif route and hasattr(route, key) and str(getattr(route, key)).lower().find(search_filter.lower()) != -1:
                searched_dict[key] = value
        route_data = searched_dict

    return render(request, 'views/route_details.html', {'route': route, 'route_data': route_data})


@login_required
def routeDetailsEdit(request, pk):
    route = get_object_or_404(Route, pk=pk)
    if request.method == 'POST':
        form = RouteForm(request.POST, instance=route)
        if form.is_valid():
            route = form.save(commit=False)
            route.save()
        return redirect('routeDetails', pk=pk)
    else:
        form = RouteForm(instance=route)
    return render(request, 'views/route_details_edit.html', {'form': form, 'route': route})


@login_required
def chatRooms(request):
    routes = Route.objects.all()
    if request.method == 'GET':
        if request.GET.get('searching'):
            search_filter = request.GET.get('searching')
            routes = routes.filter(Q(destinationAlias__icontains=search_filter) | Q(
                originAlias__icontains=search_filter))
    return render(request, 'views/chat_rooms.html', {'routes': routes})


@login_required
def chatRoomDetails(request, pk):
    response = get_messages(request, pk)
    data = json.loads(response.content)

    print(data)  # Inspect the structure of the data

    # Since data is a list of messages
    messages = data

    # Retrieve the user objects and attach them to the messages
    for message in messages:
        sender_id = message['sender']
        sender = User.objects.get(pk=sender_id)
        message['sender'] = sender

    route = get_object_or_404(Route, pk=pk)

    return render(request, 'views/chat_room_details.html', {'messages': messages, 'route': route})


def login(request):
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            username = form.cleaned_data['username']
            password = form.cleaned_data['password']
            if username == 'ppf' and password == 'ppf_not_for_you':
                # Set session variable to indicate successful login
                request.session['is_logged_in'] = True
                return HttpResponseRedirect(reverse('users'))
            else:
                form.add_error(None, 'Invalid username or password')
    else:
        form = LoginForm()
    return render(request, 'views/login.html', {'form': form})


def get_messages(request, pk):
    route = get_object_or_404(Route, pk=pk)
    driver = get_object_or_404(User, pk=route.driver.pk)
    token = Token.objects.get(user=driver).key
    auth_header = 'Token ' + token
    url = "http://chat-engine:8000/room/" + str(pk) + "/messages"
    response = requests.get(url, headers={'Authorization': auth_header})
    return response

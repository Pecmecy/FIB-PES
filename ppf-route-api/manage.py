#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def main():
    """Run administrative tasks."""
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "routeApi.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()

# {
# "originAlias": "Tarragona",
# "originLat": 41.11905889346404,
# "originLon": 1.2454971584891437,
# "destinationAlias": "Platja d'Aro",
# "destinationLat": 41.817869338317905,
# "destinationLon": 3.0668585027106294,
# "departureTime": "2024-10-10T10:00:00Z",
# "freeSeats": 4,
# "price": 63.50
# }

from time import sleep
from requests import get, RequestException
from django.core.management.base import BaseCommand
from common.models.charger import LocationCharger, ChargerVelocity, ChargerLocationType
import logging
import os

SEED_TIMEOUT = 5 * 60
URL_CAT = "https://analisi.transparenciacatalunya.cat/resource/tb2m-m33b.json"


class Command(BaseCommand):
    help = "Populates the database with charger data from the API"
    logPath = "api/logs"

    def print(self, message):
        self.stdout.write(self.style.NOTICE(message))

    def logFatal(self, message):
        if not os.path.exists(self.logPath):
            os.makedirs(self.logPath)
        self.print("Fatal error: " + message)
        logging.basicConfig(filename="api/logs/db_logs.log", encoding="utf-8", level=logging.FATAL)
        logging.fatal(message)

    def handle(self, *args, **options):
        accepted_types = ["MENNEKES", "SCHUKO", "TESLA", "CHADEMO", "CCS COMBO2"]
        t = 0.5
        limit = 50
        offset = 0

        self.print("Seeding database with charger data...")
        while True:
            data = []
            try:
                self.print(f"Fetching data: offset={offset}")
                response = get(f"{URL_CAT}?$limit={limit}&$offset={offset}")
            except RequestException as error:
                self.logFatal(error)
                self.print("Error while trying to fetch data from the API")
                return

            data = response.json()
            if len(data) <= 0:
                break
            else:
                saveData(self, data, accepted_types)
                offset += limit
                t += 0.5
                sleep(0.5)
                if t >= SEED_TIMEOUT:
                    self.logFatal("Timeout while trying to fetch data from the API")
                    break
            del data
        self.print("Data seeded successfully")

    def clear_data(self):
        try:
            LocationCharger.objects.all().delete()
        except:
            self.logFatal("Error while trying to delete data from the database")
            return


def saveData(self, data, accepted_types):
    logger = logging.getLogger(__name__)
    for item in data:

        # Create LocationCharger object
        charger = LocationCharger(
            promotorGestor=item["promotor_gestor"],
            access=item["acces"],
            kw=item["kw"],
            acDc=item["ac_dc"],
            latitud=item["latitud"],
            longitud=item["longitud"],
            adreA=item["adre_a"],
        )
        charger.save()

        # Add connection types
        connection_types = item["tipus_connexi"].upper()
        for accepted_type in accepted_types:
            if accepted_type in connection_types:
                connection_type = accepted_type
                try:
                    charger_type = ChargerLocationType.objects.get(chargerType=connection_type)
                    charger.connectionType.add(charger_type)

                except Exception as error:
                    self.logFatal(error)
                    self.print(f"Error while trying to add connection type: {connection_type}")

        # Add velocities
        velocities = item["tipus_velocitat"].split(" i ")
        for velocity in velocities:
            try:
                charger_velocity = ChargerVelocity.objects.get(velocity=velocity.strip())
                charger.velocities.add(charger_velocity)

            except Exception as error:
                self.logFatal(error)
                self.print(f"Error while trying to add velocity: {velocity}")

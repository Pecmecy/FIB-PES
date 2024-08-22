from django.core.management.base import BaseCommand
from api.management.commands.seed import Command as SeedCommand


class Command(BaseCommand):
    help = 'Clears the data'

    def handle(self, *args, **options):
        seed_command = SeedCommand()
        self.stdout.write(self.style.NOTICE("Clearing data..."))
        seed_command.clear_data()
        self.stdout.write(self.style.SUCCESS('Data cleared successfully'))

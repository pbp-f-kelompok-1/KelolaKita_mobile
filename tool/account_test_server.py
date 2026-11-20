"""Serve the real sibling Django project with an isolated in-memory database.

Run with the backend virtualenv's Python. Never opens its db.sqlite3.
"""
import argparse
import os
import sys
from pathlib import Path
from wsgiref.simple_server import make_server

sys.dont_write_bytecode = True
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--backend", type=Path, required=True)
parser.add_argument("--port", type=int, default=8765)
args = parser.parse_args()
sys.path.insert(0, str(args.backend.resolve()))
os.environ["DJANGO_SETTINGS_MODULE"] = "ProjectKelolaKita.settings"
os.environ["PRODUCTION"] = "False"

import django  # noqa: E402
from django.conf import settings  # noqa: E402

# Override before setup, migrations, or any request can open a database.
settings.DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"}}
settings.ALLOWED_HOSTS = ["localhost", "127.0.0.1"]
settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "browser_reload" not in m]
django.setup()

from django.core.management import call_command  # noqa: E402
from django.core.wsgi import get_wsgi_application  # noqa: E402

call_command("migrate", verbosity=0, interactive=False)
with make_server("127.0.0.1", args.port, get_wsgi_application()) as server:
    print(f"Isolated Django account server ready: http://127.0.0.1:{args.port}", flush=True)
    server.serve_forever()

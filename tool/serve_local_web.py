"""Serve Flutter build/web and proxy Django accounts/API on the same origin.

For local development only; keeps normal Django CSRF and browser cookie checks.
"""
import argparse
import http.client
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

HOP_HEADERS = {"connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
               "te", "trailer", "transfer-encoding", "upgrade"}


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith(("/accounts/", "/api/")):
            self.proxy()
        else:
            super().do_GET()

    def do_POST(self):
        if self.path.startswith("/accounts/"):
            self.proxy()
        else:
            self.send_error(404)

    def proxy(self):
        upstream = self.server.django
        connection_type = http.client.HTTPSConnection if upstream.scheme == "https" else http.client.HTTPConnection
        connection = connection_type(upstream.hostname, upstream.port, timeout=20)
        try:
            # Preserve browser Host/Origin together so Django verifies same origin.
            headers = {key: value for key, value in self.headers.items() if key.lower() not in HOP_HEADERS}
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length) if length else None
            connection.request(self.command, self.path, body, headers)
            response = connection.getresponse()
            data = response.read()
            self.send_response(response.status)
            for key, value in response.getheaders():
                if key.lower() not in HOP_HEADERS | {"content-length"}:
                    self.send_header(key, value)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except (OSError, http.client.HTTPException) as error:
            self.send_error(502, f"Django unavailable: {error}")
        finally:
            connection.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--django", default="http://127.0.0.1:8000")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()
    web_root = Path(__file__).resolve().parents[1] / "build" / "web"
    if not (web_root / "index.html").is_file():
        parser.error("Run flutter build web first (see README).")
    upstream = urlsplit(args.django)
    if upstream.scheme not in {"http", "https"} or not upstream.hostname or upstream.path not in {"", "/"}:
        parser.error("--django must be an HTTP(S) origin without a path")
    with ThreadingHTTPServer(("127.0.0.1", args.port), partial(Handler, directory=str(web_root))) as server:
        server.django = upstream
        print(f"Flutter: http://127.0.0.1:{args.port} | Django: {args.django}", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()

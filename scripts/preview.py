#!/usr/bin/env python3
"""Local preview of the introduction site (standard library only).

Serves site/ with the same security headers, cache rules and /download behaviour as the
nginx config that backend/compose.yaml uses (../backend/deploy/introduction.conf.template),
so problems show up before deployment:

    conda run -n appDev python scripts/preview.py          # http://127.0.0.1:8765
    KK_DOWNLOAD_URL=https://github.com/OWNER/REPO/releases/latest \
        conda run -n appDev python scripts/preview.py
"""
import argparse
import os
import re
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

SITE = Path(__file__).resolve().parent.parent / "site"
# Same rule as the nginx config: a plain https URL redirects, anything else shows coming-soon.
DOWNLOAD_URL = re.compile(r"https://[A-Za-z0-9._~:/?#@!&=+,%-]+")

# Keep in sync with ../backend/deploy/introduction.conf.template.
SECURITY_HEADERS = {
    "Content-Security-Policy": (
        "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; font-src 'self'; "
        "connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
    ),
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), interest-cohort=()",
}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(SITE), **kwargs)

    def end_headers(self):
        for name, value in SECURITY_HEADERS.items():
            self.send_header(name, value)
        path = urlsplit(self.path).path
        if path == "/download" or getattr(self, "_download", False):
            self.send_header("Cache-Control", "no-store")
        elif path.startswith("/assets/"):
            self.send_header("Cache-Control", "public, max-age=86400")
        else:
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def _route(self):
        """Return True when the request was fully answered here."""
        path = urlsplit(self.path).path
        self._download = False
        if any(part.startswith(".") for part in path.split("/") if part):
            self.send_error(HTTPStatus.NOT_FOUND)
            return True
        if path == "/download":
            self._download = True
            url = os.environ.get("KK_DOWNLOAD_URL", "")
            if DOWNLOAD_URL.fullmatch(url):
                self.send_response(HTTPStatus.FOUND)
                self.send_header("Location", url)
                self.send_header("Content-Length", "0")
                self.end_headers()
                return True
            self.path = "/coming-soon.html"
        elif path == "/favicon.ico":
            self.path = "/favicon.png"
        return False

    def do_GET(self):
        if not self._route():
            super().do_GET()

    def do_HEAD(self):
        if not self._route():
            super().do_HEAD()

    def send_error(self, code, message=None, explain=None):
        page = SITE / "404.html"
        if code == HTTPStatus.NOT_FOUND and page.is_file():
            body = page.read_bytes()
            self.send_response(code)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)
            return
        super().send_error(code, message, explain)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Serving {SITE} on http://{args.host}:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()

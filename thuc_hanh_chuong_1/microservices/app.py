"""One small HTTP image deployed three times with different SERVICE_NAME values."""

import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


SERVICE_NAME = os.environ.get("SERVICE_NAME", "users")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        route = self.path.split("?", 1)[0]
        if route not in ("/healthz", f"/{SERVICE_NAME}"):
            self.send_error(404, "Unknown route")
            return
        body = json.dumps({"service": SERVICE_NAME, "hostname": socket.gethostname(), "path": route}).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()

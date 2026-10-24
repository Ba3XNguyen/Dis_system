"""Single-threaded TCP key-value service using the KV/1.0 line protocol."""

import argparse
import logging
import socketserver
import time


MAX_LINE = 4096
COMMANDS = {"PUT", "GET", "DEL", "STATS", "QUIT"}


class KVServer(socketserver.TCPServer):
    allow_reuse_address = True

    def __init__(self, address):
        super().__init__(address, KVHandler)
        self.data = {}
        self.started = time.monotonic()
        self.served = 0

    def process(self, raw):
        """Return (wire response, close connection). All responses end in LF."""
        self.served += 1
        try:
            line = raw.decode("utf-8")
        except UnicodeDecodeError:
            return "400 BAD_REQUEST\n", False
        if not line.endswith("\n"):
            return "400 BAD_REQUEST\n", False
        line = line[:-1].removesuffix("\r")
        # split(' ') intentionally rejects repeated spaces and missing fields.
        fields = line.split(" ")
        if fields[0] != "KV/1.0":
            return "426 UPGRADE_REQUIRED\n", False
        if len(fields) < 2 or fields[1] not in COMMANDS:
            return "400 BAD_REQUEST\n", False
        command = fields[1]
        expected = {"PUT": 4, "GET": 3, "DEL": 3, "STATS": 2, "QUIT": 2}[command]
        if len(fields) != expected or any(not item or any(c.isspace() for c in item) for item in fields):
            return "400 BAD_REQUEST\n", False
        if command == "PUT":
            key, value = fields[2], fields[3]
            created = key not in self.data
            self.data[key] = value
            return ("201 CREATED\n" if created else "200 OK\n"), False
        if command == "GET":
            value = self.data.get(fields[2])
            return (f"200 OK {value}\n" if value is not None else "404 NOT_FOUND\n"), False
        if command == "DEL":
            if fields[2] not in self.data:
                return "404 NOT_FOUND\n", False
            del self.data[fields[2]]
            return "204 NO_CONTENT\n", False
        if command == "STATS":
            uptime = int(time.monotonic() - self.started)
            return f"200 OK keys={len(self.data)} uptime={uptime}s served={self.served}\n", False
        return "200 OK bye\n", True


class KVHandler(socketserver.StreamRequestHandler):
    def handle(self):
        self.request.settimeout(60)
        while True:
            try:
                raw = self.rfile.readline(MAX_LINE + 1)
            except TimeoutError:
                return
            if not raw:
                return
            if len(raw) > MAX_LINE:
                # Discard the rest of this oversized request before continuing.
                while not raw.endswith(b"\n"):
                    raw = self.rfile.readline(MAX_LINE + 1)
                    if not raw:
                        return
                self.server.served += 1
                reply, close = "400 BAD_REQUEST\n", False
                shown = "<request too long>"
            else:
                shown = repr(raw)
                try:
                    reply, close = self.server.process(raw)
                except Exception:
                    logging.exception("Unexpected server error")
                    reply, close = "500 SERVER_ERROR\n", False
            logging.info("%s request=%s response=%s", self.client_address, shown, reply.rstrip())
            try:
                self.wfile.write(reply.encode("utf-8"))
                self.wfile.flush()
            except OSError:
                return
            if close:
                return


def main():
    parser = argparse.ArgumentParser(description="KV/1.0 TCP server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=5050)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    with KVServer((args.host, args.port)) as server:
        logging.info("KVSS listening at %s:%s", *server.server_address)
        try:
            server.serve_forever(poll_interval=0.1)
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()

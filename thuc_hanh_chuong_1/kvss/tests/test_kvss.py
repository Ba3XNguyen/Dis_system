"""Ten integration cases using real TCP sockets against the baseline server."""

import re
import socket
import sys
import threading
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server import KVServer  # noqa: E402


class KVIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = KVServer(("127.0.0.1", 0))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.address = cls.server.server_address

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)

    def exchange(self, requests):
        with socket.create_connection(self.address, timeout=2) as sock:
            sock.settimeout(2)
            with sock.makefile("rb") as reader:
                return [self._send(sock, reader, request) for request in requests]

    @staticmethod
    def _send(sock, reader, request):
        sock.sendall(request if isinstance(request, bytes) else request.encode("utf-8"))
        return reader.readline().decode("utf-8")

    def test_01_put_and_get(self):
        self.assertEqual(self.exchange(["KV/1.0 PUT a Alice\n", "KV/1.0 GET a\n"]),
                         ["201 CREATED\n", "200 OK Alice\n"])

    def test_02_overwrite(self):
        self.assertEqual(self.exchange(["KV/1.0 PUT b old\n", "KV/1.0 PUT b new\n", "KV/1.0 GET b\n"]),
                         ["201 CREATED\n", "200 OK\n", "200 OK new\n"])

    def test_03_delete_twice(self):
        self.assertEqual(self.exchange(["KV/1.0 PUT c value\n", "KV/1.0 DEL c\n", "KV/1.0 DEL c\n"]),
                         ["201 CREATED\n", "204 NO_CONTENT\n", "404 NOT_FOUND\n"])

    def test_04_stats(self):
        (reply,) = self.exchange(["KV/1.0 STATS\n"])
        self.assertRegex(reply, r"^200 OK keys=\d+ uptime=\d+s served=\d+\n$")

    def test_05_quit(self):
        with socket.create_connection(self.address, timeout=2) as sock:
            sock.settimeout(2)
            sock.sendall(b"KV/1.0 QUIT\n")
            self.assertEqual(sock.recv(100), b"200 OK bye\n")
            self.assertEqual(sock.recv(100), b"")

    def test_06_missing_version(self):
        self.assertEqual(self.exchange(["GET a\n"]), ["426 UPGRADE_REQUIRED\n"])

    def test_07_wrong_version(self):
        self.assertEqual(self.exchange(["KV/2.0 GET a\n"]), ["426 UPGRADE_REQUIRED\n"])

    def test_08_missing_value(self):
        self.assertEqual(self.exchange(["KV/1.0 PUT z\n"]), ["400 BAD_REQUEST\n"])

    def test_09_unknown_command(self):
        self.assertEqual(self.exchange(["KV/1.0 POTT a Alice\n"]), ["400 BAD_REQUEST\n"])

    def test_10_stream_framing_and_utf8(self):
        with socket.create_connection(self.address, timeout=2) as sock:
            sock.settimeout(2)
            with sock.makefile("rb") as reader:
                sock.sendall("KV/1.0 PUT tên ".encode("utf-8"))
                sock.sendall("Hà\nKV/1.0 GET tên\n".encode("utf-8"))
                self.assertEqual(reader.readline().decode("utf-8"), "201 CREATED\n")
                self.assertEqual(reader.readline().decode("utf-8"), "200 OK Hà\n")


if __name__ == "__main__":
    unittest.main()

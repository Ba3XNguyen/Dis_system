"""Interactive KV/1.0 TCP client. Enter commands or full protocol lines."""

import argparse
import socket
import sys


def main():
    parser = argparse.ArgumentParser(description="KV/1.0 command-line client")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=5050)
    args = parser.parse_args()
    try:
        with socket.create_connection((args.host, args.port), timeout=10) as sock:
            sock.settimeout(60)
            with sock.makefile("rb") as response_stream:
                for line in sys.stdin:
                    line = line.rstrip("\r\n")
                    if not line:
                        continue
                    request = line if line.startswith("KV/") else "KV/1.0 " + line
                    sock.sendall((request + "\n").encode("utf-8"))
                    response = response_stream.readline()
                    if not response:
                        print("Server closed connection", file=sys.stderr)
                        return 1
                    sys.stdout.write(response.decode("utf-8"))
                    sys.stdout.flush()
                    if request == "KV/1.0 QUIT":
                        break
    except (OSError, UnicodeError) as exc:
        print(f"Connection error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

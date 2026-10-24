#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[[ -f build/RPCClient.class ]] || { echo 'Chay bash build.sh truoc.' >&2; exit 1; }
case "${1:-}" in
  server) shift; exec java -cp 'build:lib/*' RPCServer "$@" ;;
  client) shift; exec java -cp 'build:lib/*' RPCClient "$@" ;;
  test) shift; exec java -cp 'build:lib/*' RpcIntegrationTest "$@" ;;
  *) echo 'Usage: bash run.sh server [--delay-ms 2000] | client [n ...] | test'; exit 1 ;;
esac

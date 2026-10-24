#!/usr/bin/env bash
set -euo pipefail
name=ch2-rabbitmq
case "${1:-}" in
  start)
    if docker container inspect "$name" >/dev/null 2>&1; then
      docker start "$name" >/dev/null
    else
      docker run -d --name "$name" -p 127.0.0.1:5672:5672 -p 127.0.0.1:15672:15672 rabbitmq:4.1.4-management >/dev/null
    fi
    for ((i=0; i<60; i++)); do
      if docker exec "$name" rabbitmq-diagnostics -q ping >/dev/null 2>&1; then
        echo 'Broker ready. Management: http://localhost:15672 (guest / guest)'; exit 0
      fi
      sleep 1
    done
    echo "Broker chua san sang. Xem: docker logs $name" >&2; exit 1 ;;
  queues) docker exec "$name" rabbitmqctl list_queues name messages_ready messages_unacknowledged ;;
  stop) docker stop "$name" ;;
  *) echo 'Usage: bash broker.sh start | queues | stop'; exit 1 ;;
esac

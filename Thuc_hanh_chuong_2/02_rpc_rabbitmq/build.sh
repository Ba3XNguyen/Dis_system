#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v javac >/dev/null || { echo 'Can JDK: sudo apt install openjdk-17-jdk' >&2; exit 1; }
mkdir -p lib build
fetch() {
  local path="$1" output="$2"
  if [[ ! -s "$output" ]]; then
    curl --fail --location --retry 2 "https://repo.maven.apache.org/maven2/$path" -o "$output.tmp"
    mv "$output.tmp" "$output"
  fi
}
fetch 'com/rabbitmq/amqp-client/5.25.0/amqp-client-5.25.0.jar' lib/amqp-client-5.25.0.jar
fetch 'org/slf4j/slf4j-api/2.0.17/slf4j-api-2.0.17.jar' lib/slf4j-api-2.0.17.jar
fetch 'org/slf4j/slf4j-simple/2.0.17/slf4j-simple-2.0.17.jar' lib/slf4j-simple-2.0.17.jar
javac -encoding UTF-8 -d build -cp 'lib/*' src/*.java test/*.java
java -cp 'build:lib/*' FibonacciTest

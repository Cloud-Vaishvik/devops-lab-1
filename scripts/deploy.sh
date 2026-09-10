#!/usr/bin/env bash
# Deploy (or stop) the packaged app on a staging port.
#
#   deploy.sh <artifact.tar.gz> <deploy_dir> <port> <version>
#   deploy.sh --stop "" <deploy_dir> <port> ""
#
# Idempotent: stops any previous instance recorded in the pidfile before
# starting a new one, so repeated Jenkins builds do not leak processes or
# collide on the port.
set -euo pipefail

MODE="start"
# shift so the remaining positional args line up identically in both modes
if [ "${1:-}" = "--stop" ]; then MODE="stop"; shift; fi

ARTIFACT="${1:-}"
DEPLOY_DIR="${2:-./staging}"
PORT="${3:-3001}"
VERSION="${4:-dev}"
PIDFILE="$DEPLOY_DIR/app.pid"
LOGFILE="$DEPLOY_DIR/app.log"

stop_existing() {
  if [ -f "$PIDFILE" ]; then
    pid="$(cat "$PIDFILE")"
    if kill -0 "$pid" 2>/dev/null; then
      echo "stopping previous instance (pid $pid)"
      kill "$pid" 2>/dev/null || true
      # SIGTERM first: server.js drains connections. Escalate only if it hangs.
      for _ in $(seq 1 10); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.5
      done
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
  fi
}

if [ "$MODE" = "stop" ]; then
  stop_existing
  echo "staging stopped"
  exit 0
fi

if [ ! -f "$ARTIFACT" ]; then
  echo "ERROR: artifact not found: $ARTIFACT" >&2
  exit 1
fi

stop_existing
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

echo "unpacking $ARTIFACT -> $DEPLOY_DIR"
tar -xzf "$ARTIFACT" -C "$DEPLOY_DIR"

echo "installing production dependencies"
( cd "$DEPLOY_DIR" && npm ci --omit=dev --no-audit --no-fund )

echo "starting on port $PORT as version $VERSION"
(
  cd "$DEPLOY_DIR"
  PORT="$PORT" APP_VERSION="$VERSION" BUILD_NUMBER="${BUILD_NUMBER:-local}" \
    nohup node src/server.js > "app.log" 2>&1 &
  echo $! > "app.pid"
)

# Wait for readiness rather than sleeping a fixed amount: a fixed sleep either
# wastes time or races the process start.
for i in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1; then
    echo "healthy after ${i} attempt(s) (pid $(cat "$PIDFILE"))"
    exit 0
  fi
  sleep 0.5
done

echo "ERROR: app did not become healthy within 15s" >&2
echo "--- app.log ---" >&2
cat "$LOGFILE" >&2 || true
exit 1

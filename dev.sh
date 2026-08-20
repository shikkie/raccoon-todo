#!/usr/bin/env bash
# Launch, restart, or stop the Raccoon Stash API + Vite UI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$ROOT/.dev"
PID_DIR="$RUN_DIR/pids"
LOG_DIR="$RUN_DIR/logs"

API_NAME="api"
API_HOST="127.0.0.1"
API_PORT="9999"
API_PID_FILE="$PID_DIR/api.pid"
API_LOG="$LOG_DIR/api.log"

FRONT_NAME="frontend"
FRONT_HOST="0.0.0.0"
FRONT_PORT="9998"
FRONT_PID_FILE="$PID_DIR/frontend.pid"
FRONT_LOG="$LOG_DIR/frontend.log"

VENV="$ROOT/backend/.venv"
STOP_WAIT_SECS=8
LISTEN_WAIT_SECS=15

usage() {
  cat <<EOF
Usage: $(basename "$0") [start|stop|restart|status|check]

  start     Launch API (:${API_PORT}) and frontend (:${FRONT_PORT}) [default]
  stop      Stop both, using tracked PIDs
  restart   Stop then start
  status    Show PIDs, ports, and whether they look alive
  check     Run pytest (extra args are passed through)

API listens on ${API_HOST}:${API_PORT}
Frontend listens on ${FRONT_HOST}:${FRONT_PORT} (any Host header)
Logs: ${LOG_DIR}/
EOF
}

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Primary non-loopback IPv4 of this box (the address other machines can hit).
lan_ipv4() {
  python3 - <<'PY'
import socket
from ipaddress import ip_address

def usable(ip: str) -> bool:
    try:
        addr = ip_address(ip)
    except ValueError:
        return False
    return (
        addr.version == 4
        and not addr.is_loopback
        and not addr.is_unspecified
        and not addr.is_link_local
        and not addr.is_multicast
    )

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    sock.connect(("1.1.1.1", 80))
    ip = sock.getsockname()[0]
    if usable(ip):
        print(ip)
        raise SystemExit(0)
except OSError:
    pass
finally:
    sock.close()

try:
    for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
        ip = info[4][0]
        if usable(ip):
            print(ip)
            raise SystemExit(0)
except socket.gaierror:
    pass

raise SystemExit(1)
PY
}

frontend_url() {
  local ip
  if ip="$(lan_ipv4)"; then
    printf 'http://%s:%s/' "$ip" "$FRONT_PORT"
  else
    die "could not find a non-loopback IPv4 to advertise for the frontend"
  fi
}

ensure_dirs() {
  mkdir -p "$PID_DIR" "$LOG_DIR"
}

pid_alive() {
  local pid="${1:-}"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

read_pid() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  tr -d '[:space:]' <"$file"
}

tracked_alive() {
  local pid
  pid="$(read_pid "$1")"
  pid_alive "$pid"
}

descendants() {
  local pid="$1"
  local kids
  kids="$(pgrep -P "$pid" 2>/dev/null || true)"
  local kid
  for kid in $kids; do
    descendants "$kid"
    printf '%s\n' "$kid"
  done
}

kill_tree() {
  local pid="$1"
  local sig="${2:-TERM}"
  local targets=("$pid")
  local kid
  while IFS= read -r kid; do
    [[ -n "$kid" ]] && targets+=("$kid")
  done < <(descendants "$pid")

  local t
  for t in "${targets[@]}"; do
    kill "-$sig" "$t" 2>/dev/null || true
  done
}

wait_gone() {
  local pid="$1"
  local i
  for i in $(seq 1 "$STOP_WAIT_SECS"); do
    pid_alive "$pid" || return 0
    sleep 1
  done
  return 1
}

stop_one() {
  local name="$1"
  local pidfile="$2"
  local pid

  pid="$(read_pid "$pidfile")"
  if [[ -z "$pid" ]]; then
    rm -f "$pidfile"
    log "$name: not tracked"
    return 0
  fi
  if ! pid_alive "$pid"; then
    rm -f "$pidfile"
    log "$name: stale pid $pid (already gone)"
    return 0
  fi

  log "$name: stopping pid $pid"
  kill -- "-$pid" 2>/dev/null || true
  kill_tree "$pid" TERM
  if ! wait_gone "$pid"; then
    log "$name: still alive, sending KILL"
    kill -- "-$pid" 2>/dev/null || true
    kill_tree "$pid" KILL
    wait_gone "$pid" || true
  fi
  rm -f "$pidfile"
}

can_bind() {
  local host="$1"
  local port="$2"
  python3 - "$host" "$port" <<'PY'
import socket
import sys

host, port = sys.argv[1], int(sys.argv[2])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.bind((host, port))
except OSError as exc:
    sys.stderr.write(f"{host}:{port} — {exc.strerror or exc}\n")
    sys.exit(1)
finally:
    sock.close()
PY
}

require_port_free() {
  local name="$1"
  local host="$2"
  local port="$3"
  if can_bind "$host" "$port"; then
    return 0
  fi
  die "$name cannot bind ${host}:${port} (in use or not permitted). Refusing to start."
}

port_open() {
  local host="$1"
  local port="$2"
  python3 - "$host" "$port" <<'PY'
import socket
import sys

host, port = sys.argv[1], int(sys.argv[2])
try:
    with socket.create_connection((host, port), timeout=0.25):
        pass
except OSError:
    sys.exit(1)
PY
}

wait_for_listen() {
  local name="$1"
  local host="$2"
  local port="$3"
  local pidfile="$4"
  local logfile="$5"
  local probe_host="$host"
  [[ "$host" == "0.0.0.0" ]] && probe_host="127.0.0.1"

  local i
  for i in $(seq 1 "$LISTEN_WAIT_SECS"); do
    if ! tracked_alive "$pidfile"; then
      log "$name exited before binding ${host}:${port}"
      [[ -f "$logfile" ]] && tail -n 40 "$logfile" >&2
      return 1
    fi
    if port_open "$probe_host" "$port"; then
      return 0
    fi
    sleep 1
  done

  log "$name did not listen on ${host}:${port} within ${LISTEN_WAIT_SECS}s"
  [[ -f "$logfile" ]] && tail -n 40 "$logfile" >&2
  return 1
}

ensure_venv() {
  if [[ ! -x "$VENV/bin/python" ]]; then
    log "creating backend venv"
    python3 -m venv "$VENV"
  fi
  # shellcheck disable=SC1091
  source "$VENV/bin/activate"
  if [[ ! -x "$VENV/bin/flask" ]]; then
    log "installing backend requirements"
    pip install -r "$ROOT/backend/requirements.txt"
  fi
}

ensure_frontend_deps() {
  if [[ ! -d "$ROOT/frontend/node_modules" ]]; then
    log "installing frontend npm packages"
    (cd "$ROOT/frontend" && npm install)
  fi
}

refuse_if_tracked() {
  if tracked_alive "$API_PID_FILE"; then
    die "api already running (pid $(read_pid "$API_PID_FILE")); use: $0 restart"
  fi
  if tracked_alive "$FRONT_PID_FILE"; then
    die "frontend already running (pid $(read_pid "$FRONT_PID_FILE")); use: $0 restart"
  fi
  rm -f "$API_PID_FILE" "$FRONT_PID_FILE"
}

start_api() {
  : >"$API_LOG"
  (
    # shellcheck disable=SC1091
    source "$VENV/bin/activate"
    cd "$ROOT/backend"
    exec setsid flask --app app run --debug --no-reload --host "$API_HOST" --port "$API_PORT"
  ) >>"$API_LOG" 2>&1 &
  echo $! >"$API_PID_FILE"
  log "api: pid $(read_pid "$API_PID_FILE"), logging ${API_LOG}"
}

start_frontend() {
  : >"$FRONT_LOG"
  (
    cd "$ROOT/frontend"
    exec setsid npm run dev -- --host "$FRONT_HOST" --port "$FRONT_PORT" --strictPort
  ) >>"$FRONT_LOG" 2>&1 &
  echo $! >"$FRONT_PID_FILE"
  log "frontend: pid $(read_pid "$FRONT_PID_FILE"), logging ${FRONT_LOG}"
}

cmd_stop() {
  ensure_dirs
  stop_one "$FRONT_NAME" "$FRONT_PID_FILE"
  stop_one "$API_NAME" "$API_PID_FILE"
}

cmd_start() {
  ensure_dirs
  ensure_venv
  ensure_frontend_deps
  refuse_if_tracked
  require_port_free "$API_NAME" "$API_HOST" "$API_PORT"
  require_port_free "$FRONT_NAME" "$FRONT_HOST" "$FRONT_PORT"

  start_api
  start_frontend

  local failed=0
  wait_for_listen "$API_NAME" "$API_HOST" "$API_PORT" "$API_PID_FILE" "$API_LOG" || failed=1
  wait_for_listen "$FRONT_NAME" "$FRONT_HOST" "$FRONT_PORT" "$FRONT_PID_FILE" "$FRONT_LOG" || failed=1
  if [[ "$failed" -ne 0 ]]; then
    cmd_stop
    die "startup failed; stopped anything we launched"
  fi

  log
  log "API       http://${API_HOST}:${API_PORT}/api/health"
  log "Frontend  $(frontend_url)  (bound ${FRONT_HOST}, any Host)"
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_check() {
  ensure_venv
  log "running pytest in backend/"
  (cd "$ROOT/backend" && pytest "$@")
}

cmd_status() {
  ensure_dirs
  local api_pid front_pid
  api_pid="$(read_pid "$API_PID_FILE")"
  front_pid="$(read_pid "$FRONT_PID_FILE")"

  if pid_alive "$api_pid"; then
    log "api: running pid ${api_pid} on ${API_HOST}:${API_PORT}"
  else
    log "api: not running"
  fi
  if pid_alive "$front_pid"; then
    log "frontend: running pid ${front_pid} — $(frontend_url)"
  else
    log "frontend: not running"
  fi
}

main() {
  local cmd="${1:-start}"
  if [[ $# -gt 0 ]]; then
    shift
  fi
  case "$cmd" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    restart) cmd_restart ;;
    status) cmd_status ;;
    check) cmd_check "$@" ;;
    -h|--help|help) usage ;;
    *)
      usage >&2
      die "unknown command: $cmd"
      ;;
  esac
}

main "$@"

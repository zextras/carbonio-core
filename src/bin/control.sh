#!/bin/bash
# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only
# Compatibility wrapper — delegates zmcontrol to configd control.

CONFIGD=/opt/zextras/bin/configd

[ -x "$CONFIGD" ] || {
  echo "Error: configd binary not found at $CONFIGD" >&2
  exit 1
}

usage() {
  "$CONFIGD" release 2>/dev/null
  echo "$0 [-v -h -H <host>] command [args]"
  echo
  printf '\t-v:\tdisplay version\n'
  printf '\t-V:\tdisplay advanced version information\n'
  printf '\t-h:\tprint usage statement\n'
  printf '\t-H:\tHost name (localhost)\n'
  echo
  printf '\tCommand in:\n'
  printf '\t\t%-20s%30s\n' restart "Restart services" shutdown "Shutdown services" \
    startup "Startup services" status "Display service status" stop "Stop services" start "Start services"
}

HOST=""
while [ $# -gt 0 ]; do
  case "$1" in
    -v) exec "$CONFIGD" release ;;
    -V) exec "$CONFIGD" release --packages ;;
    -h | --help)
      usage
      exit 0
      ;;
    -H)
      HOST="$2"
      shift 2
      ;;
    *) break ;;
  esac
done

if [ -n "$HOST" ]; then
  # Remote execution stays on the legacy Perl SSH helpers (zmrc/zmrcd).
  case "$1" in
    start | startup) remote=startup ;;
    stop | shutdown) remote=shutdown ;;
    restart) remote=restart ;;
    status) remote=status ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
  echo "HOST:${HOST} ${remote}" | /opt/zextras/libexec/zmrc "$HOST"
  exit $?
fi

case "$1" in
  start | startup) exec "$CONFIGD" control start ;;
  stop | shutdown) exec "$CONFIGD" control stop ;;
  restart) exec "$CONFIGD" control restart ;;
  status) exec "$CONFIGD" control status ;;
  *)
    usage >&2
    exit 1
    ;;
esac

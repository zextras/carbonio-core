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
  echo "$0 [-v -V -h] command [args]"
  echo
  printf '\t-v:\tdisplay version\n'
  printf '\t-V:\tdisplay advanced version information\n'
  printf '\t-h:\tprint usage statement\n'
  echo
  printf '\tCommand in:\n'
  printf '\t\t%-20s%30s\n' restart "Restart services" shutdown "Shutdown services" \
    startup "Startup services" status "Display service status" stop "Stop services" start "Start services"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -v) exec "$CONFIGD" release ;;
    -V) exec "$CONFIGD" release --packages ;;
    -h | --help)
      usage
      exit 0
      ;;
    -H)
      # Never worked in legacy control.pl (getopts ran after the command was read).
      # Remote operations use /opt/zextras/libexec/zmrc directly.
      echo "Error: remote execution (-H) is not supported; use /opt/zextras/libexec/zmrc" >&2
      exit 1
      ;;
    *) break ;;
  esac
done

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

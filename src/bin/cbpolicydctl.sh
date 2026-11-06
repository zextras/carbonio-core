#!/bin/bash
# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only
# Compatibility wrapper — delegates to configd service.
CONFIGD=/opt/zextras/bin/configd
[ -x "$CONFIGD" ] || {
  echo "Error: configd binary not found at $CONFIGD" >&2
  exit 1
}
exec "$CONFIGD" service "${1:-}" cbpolicyd "${@:2}"

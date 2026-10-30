#!/bin/bash

# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

source /opt/zextras/bin/zmshutil || exit 1
zmsetvars

zmconfigd_request "${zimbra_configrewrite_timeout}" REWRITE "$@" >/dev/null
rc=$?

# If nc fails to connect, the configd service should be running
# No fallback needed - configd should be managed by systemd
if [ $rc -ne 0 ]; then
  echo "Warning: Could not connect to configd service on port ${zmconfigd_listen_port}" >&2
  echo "Ensure carbonio-configd.service is running" >&2
else
  sleep 5
fi
exit $rc

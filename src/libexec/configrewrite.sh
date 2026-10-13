#!/bin/bash

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

source /opt/zextras/bin/zmshutil || exit 1
zmsetvars

zmconfigd_request "${zimbra_configrewrite_timeout}" REWRITE "$@" >/dev/null
rc=$?

# If zmconfigd is not listening, run it directly
if [ $rc -eq 1 ]; then
  /opt/zextras/libexec/zmconfigd "$@"
  rc=$?
  stty echo
else
  sleep 5
fi
exit $rc

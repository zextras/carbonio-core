#!/bin/bash
# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

# zmsyslogsetup is carbonio-configd's "setup syslog"; the name stays for its callers.
exec /opt/zextras/libexec/setup syslog "$@"

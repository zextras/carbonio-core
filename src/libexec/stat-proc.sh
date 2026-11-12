#!/bin/bash
# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only

# zmstat-proc is carbonio-configd's "setup stat proc"; the name stays for its callers.
exec /opt/zextras/libexec/setup stat proc "$@"

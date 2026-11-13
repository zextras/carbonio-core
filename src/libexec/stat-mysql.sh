#!/bin/bash
# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only

# zmstat-mysql is carbonio-configd's "configd stat mysql"; the name stays for its callers.
exec /opt/zextras/bin/configd stat mysql "$@"

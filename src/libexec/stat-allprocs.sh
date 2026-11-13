#!/bin/bash
# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only

# zmstat-allprocs is carbonio-configd's "configd stat allprocs"; the name stays for its callers.
exec /opt/zextras/bin/configd stat allprocs "$@"

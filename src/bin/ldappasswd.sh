#!/bin/bash
# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

# zmldappasswd is carbonio-configd's "setup ldap-passwd"; the name stays for its
# callers. Without the password argument it reads the password from stdin.
exec /opt/zextras/libexec/setup ldap-passwd "$@"

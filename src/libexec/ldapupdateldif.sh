#!/bin/bash
# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only

# zmldapupdateldif is carbonio-configd's "setup ldap-update-ldif"; the name stays for its callers.
exec /opt/zextras/libexec/setup ldap-update-ldif "$@"

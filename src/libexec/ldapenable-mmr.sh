#!/bin/bash
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: AGPL-3.0-only

# zmldapenable-mmr is carbonio-configd's "setup ldap-enable-mmr"; the name stays for its callers.
exec /opt/zextras/libexec/setup ldap-enable-mmr "$@"

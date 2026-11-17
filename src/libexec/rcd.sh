#!/bin/bash
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: AGPL-3.0-only

# zmrcd is carbonio-configd's "setup rcd"; the name stays for its callers
# (the forced command of authorized_keys and zimbraRemoteManagementCommand).
exec /opt/zextras/libexec/setup rcd "$@"

#!/bin/bash
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# zmsshkeygen is carbonio-configd's "setup ssh-keygen"; the name stays for its callers.
exec /opt/zextras/libexec/setup ssh-keygen "$@"

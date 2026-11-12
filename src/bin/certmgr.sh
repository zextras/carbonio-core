#!/bin/bash
# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only

# zmcertmgr is carbonio-configd's "setup certmgr"; the name stays for its callers
# (setup.pl, zmsetservername, zmcheckexpiredcerts, zmrc and the mailbox).
exec /opt/zextras/libexec/setup certmgr "$@"

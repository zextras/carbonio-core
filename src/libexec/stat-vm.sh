#!/bin/bash
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: AGPL-3.0-only

# zmstat-vm is carbonio-configd's "configd stat vm"; the name stays for its callers.
exec /opt/zextras/bin/configd stat vm "$@"

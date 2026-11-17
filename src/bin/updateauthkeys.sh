#!/bin/bash
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# zmupdateauthkeys is carbonio-configd's "setup update-authkeys"; the name stays for its callers.
exec /opt/zextras/libexec/setup update-authkeys "$@"

#!/bin/bash
# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
# SPDX-License-Identifier: GPL-2.0-only
#
# Compatibility wrapper — delegates zmproxyconf to configd proxy conf.
exec /opt/zextras/bin/configd proxy conf "$@"

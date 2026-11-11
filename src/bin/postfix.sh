#!/bin/bash

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

source /opt/zextras/bin/zmshutil || exit 1

if [ ! -x /opt/zextras/common/sbin/postfix ]; then
  echo "Error: postfix not installed"
  exit 1
fi

if is_systemd; then
  systemd_print
fi
zmsetvars

rewrite_mta_config() {
  /opt/zextras/libexec/zmmtainit
}

rewrite_config() {
  /opt/zextras/libexec/configrewrite mta >/dev/null 2>&1
}

if [ "$1" = "status" ] || [ "$1" = "start" ]; then
  if [ ! -f /opt/zextras/common/conf/main.cf ]; then
    # CO-4621: common/conf is root-owned; only the root helper may create main.cf
    sudo /opt/zextras/libexec/carbonio-postfix-conf set \
      mail_owner="${postfix_mail_owner}" setgid_group="${postfix_setgid_group}"
  fi
  sudo /opt/zextras/libexec/zmmtastatus 2>/dev/null
  R=$?
  if [ "$1" = "start" ]; then
    if [ "$R" = "0" ]; then
      exit 0
    fi
  else
    if [ $R != "0" ]; then
      exit 1
    else
      exit 0
    fi
  fi
fi

if [ "$1" = "start" ] || [ "$1" = "reload" ] || [ "$1" = "restart" ]; then
  rewrite_mta_config
  if [ "$2" != "norewrite" ]; then
    rewrite_config
  fi
fi

if [ -f /etc/aliases ]; then
  sudo /opt/zextras/common/sbin/postalias /etc/aliases
fi

# sudoers only allows the bare verbs (start|stop|status|reload|flush|check);
# the optional "norewrite" marker is not meant for postfix itself.
sudo /opt/zextras/common/sbin/postfix "$1"

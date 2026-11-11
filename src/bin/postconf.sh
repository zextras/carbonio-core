#!/bin/bash

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

# CO-4621: Postfix configuration under /opt/zextras/common/conf is root-owned
# and trusted by the root master process. This wrapper never runs postconf as
# root. Read-only invocations run postconf as the current user; the supported
# write modes are routed to the validating root helper:
#   postconf -e KEY=VALUE...  ->  postfix-conf set KEY=VALUE...
#   postconf -X KEY...        ->  postfix-conf unset KEY...
# Every other way of writing (-#, -M/-P/-F with '=', -e/-X combined with any
# other option) is refused.

POSTCONF=/opt/zextras/common/sbin/postconf
HELPER=/opt/zextras/libexec/postfix-conf

if [ ! -x "${POSTCONF}" ]; then
  echo "Error: postfix not installed"
  exit 1
fi

orig_args=("$@")
edit=0
delete=0
comment=0
service_mode=0
other_opts=0
operands=()

# Option scan mirroring postconf(1): getopt(3) permutes, so options may follow
# operands; "--" ends option processing.
while [ $# -gt 0 ]; do
  OPTIND=1
  while getopts ":aAbc:C:deEfFhHjlmMno:pPqtT:vxX#" opt; do
    case "${opt}" in
      e) edit=1 ;;
      X) delete=1 ;;
      '#') comment=1 ;;
      M | P | F) service_mode=1 ;;
      *) other_opts=1 ;;
    esac
  done
  shift $((OPTIND - 1))
  if [ $# -gt 0 ]; then
    operands+=("$1")
    shift
  fi
done

# getopts swallows "--" invisibly, which could hide a later option from the
# scan above; refuse it outright.
for a in "${orig_args[@]}"; do
  if [ "${a}" = "--" ]; then
    echo "postconf: '--' is not supported by this wrapper" >&2
    exit 2
  fi
done

if [ "${comment}" = 1 ]; then
  echo "postconf: -# is not permitted; use 'postconf -X KEY' or the configd" >&2
  exit 2
fi

# postconf treats "name=value" operands as an edit even without -e.
if [ "${edit}" = 0 ] && [ "${delete}" = 0 ] && [ "${service_mode}" = 0 ]; then
  for o in "${operands[@]}"; do
    case "${o}" in
      *=*) edit=1 ;;
    esac
  done
fi

run_helper() {
  if [ "${EUID}" -eq 0 ]; then
    exec "${HELPER}" "$@"
  fi
  exec sudo "${HELPER}" "$@"
}

if [ "${edit}" = 1 ] && [ "${delete}" = 1 ]; then
  echo "postconf: -e and -X cannot be combined" >&2
  exit 2
fi

if [ "${edit}" = 1 ] || [ "${delete}" = 1 ]; then
  if [ "${service_mode}" = 1 ] || [ "${other_opts}" = 1 ]; then
    echo "postconf: -e/-X cannot be combined with other options" >&2
    exit 2
  fi
  if [ "${#operands[@]}" -eq 0 ]; then
    echo "postconf: -e/-X require at least one parameter" >&2
    exit 2
  fi
  if [ "${edit}" = 1 ]; then
    run_helper set "${operands[@]}"
  else
    run_helper unset "${operands[@]}"
  fi
fi

if [ "${service_mode}" = 1 ]; then
  for o in "${operands[@]}"; do
    case "${o}" in
      *=*)
        echo "postconf: modifying master.cf through postconf is not permitted" >&2
        exit 2
        ;;
    esac
  done
fi

exec "${POSTCONF}" "${orig_args[@]}"

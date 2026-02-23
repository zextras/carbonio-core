#!/bin/bash
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# Check privileges
user=$(id -u)
if [[ ${user} -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

########## Start utility functions
bordered_title() {
  local title="| $1 |"
  local edge="${title//?/−}"
  echo "$edge"
  echo "$title"
  echo "$edge"
}

# concat $2 $1 times and print
repeated_char() {
  printf "%$1s" | tr " " "$2"
}

# print ce_alue
print_ce_alue() {
  alue=/opt/zextras/.mini_alue_ce
  if [[ -e "${alue}" ]]; then
    repeated_char 80 "-"
    echo
    fold -w 80 -s "${alue}"
    repeated_char 80 "-"
    echo $'\n'
  fi
}

########## End utility functions

########## Start Carbonio Bootstrap

if [[ -z "$1" ]] || [[ "$1" = "-c" ]]; then
  # print welcome message
  bordered_title $'Starting Carbonio Bootstrap...'

  # print product usage information
  print_ce_alue
fi

# Ensure all users and groups are created before setting directory ownership
echo "Applying systemd sysusers configurations..."
systemd-sysusers /usr/lib/sysusers.d/carbonio-*.conf >/dev/null 2>&1 || :

# Create directories and set ownership (requires users to exist first)
echo "Applying systemd tmpfiles configurations..."
systemd-tmpfiles --create /usr/lib/tmpfiles.d/carbonio-*.conf >/dev/null 2>&1 || :
echo "tmpfiles configurations applied."

# Bootstrap and start services
/opt/zextras/libexec/setup.pl "${@}"

########## End Carbonio Bootstrap

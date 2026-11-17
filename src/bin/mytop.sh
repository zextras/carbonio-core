#!/bin/bash

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

if [ "$(whoami)" != zextras ]; then
  echo "Error: must be run as zextras user"
  exit 1
fi

if [ ! -x /opt/zextras/common/bin/mysql ]; then
  echo "Error: mariadb not available"
  exit 1
fi

if [ "$1" = "-h" ]; then
  echo "Usage"
  echo "zmmytop [-h] [-r]"
  echo "-h: Display this message"
  echo "-r: Connect as root user (Default: connect as Zimbra user)"
  echo "--[no]color : Use color Default: use color if available"
  echo "--delay <seconds>: How long between display refreshes. Default: 5"
  echo "--batch : In batch mode, mytop runs only once, does not clear the screen, and places no limit on the number of lines it will print."
  echo "--[no]header : Display header"
  echo "--[no]idle : Specify if you want idle (sleeping) threads to appear in the list."
  echo "--[no]resolve : If you have skip-resolve set on MySQL (to keep it from doing a reverse"
  echo "                DNS lookup on each inbound connection), mytop can replace IP addresses with hostnames"
  echo "                Default: noresolve"
  exit 0
fi

source /opt/zextras/bin/zmshutil || exit 1
zmsetvars

if [ "$1" = "-r" ]; then
  shift
  db_user=root
  db_password=$mysql_root_password
else
  db_user=$zimbra_mysql_user
  db_password=$zimbra_mysql_password
fi

if [ -x "/opt/zextras/common/bin/mytop" ]; then
  /opt/zextras/common/bin/mytop \
    -u "$db_user" -S /run/carbonio/mysql.sock -p "$db_password" "$@"
  exit $?
fi

# mytop is not shipped with the Carbonio MariaDB package: fall back to the
# process list from mysqladmin, honouring --batch/-b and --delay (other mytop
# display options are accepted and ignored).
batch=false
delay=5
while [ $# -gt 0 ]; do
  case "$1" in
    -b | --batch) batch=true ;;
    --delay=*) delay=${1#--delay=} ;;
    --delay | -s)
      shift
      delay=$1
      ;;
  esac
  shift
done

case "$delay" in
  '' | *[!0-9]*)
    echo "Error: invalid delay: $delay" >&2
    exit 1
    ;;
esac

echo "Note: mytop is not installed, showing the MariaDB process list." >&2
export MYSQL_PWD="$db_password"
if [ "$batch" = true ]; then
  exec /opt/zextras/common/bin/mysqladmin -u "$db_user" -S /run/carbonio/mysql.sock \
    --verbose processlist
fi
exec /opt/zextras/common/bin/mysqladmin -u "$db_user" -S /run/carbonio/mysql.sock \
  --verbose -i "$delay" processlist

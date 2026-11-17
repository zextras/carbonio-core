#!/bin/bash

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

# Much faster; just call zmlocalconfig once
source /opt/zextras/bin/zmshutil || exit 1
zmsetvars -f

# Use the Carbonio-bundled JVM directly (same as zmjava).
JAVA_BIN=/opt/zextras/common/lib/jvm/java/bin/java

ZIMBRA_EXTENSIONS="backup clamscanner network carbonio-license zimbrahsm zimbrasync"
ZIMBRA_EXT_DIR="/opt/zextras/lib/ext-common"
for i in $ZIMBRA_EXTENSIONS; do
  if [ -d "/opt/zextras/lib/ext/$i" ]; then
    ZIMBRA_EXT_DIR="${ZIMBRA_EXT_DIR}:/opt/zextras/lib/ext/$i"
  fi
done

java_options="-XX:ErrorFile=/opt/zextras/log"

# JDK 9+ rejects -Djava.ext.dirs, so the extension directories are put on the
# classpath instead (every jar in each directory, as java.ext.dirs did).
if [ "${zimbra_zmjava_java_ext_dirs}" = "" ]; then
  zimbra_zmjava_java_ext_dirs=/opt/zextras/mailbox/jars:${ZIMBRA_EXT_DIR}
fi

ext_classpath=""
IFS=: read -r -a ext_dirs <<<"${zimbra_zmjava_java_ext_dirs}"
for d in "${ext_dirs[@]}"; do
  [ -n "$d" ] || continue
  ext_classpath="${ext_classpath:+${ext_classpath}:}${d%/}/*"
done

# shellcheck disable=SC2086
exec "${JAVA_BIN}" ${java_options} \
  -client ${zimbra_zmjava_options} \
  -Dzimbra.home=/opt/zextras \
  -classpath "${ext_classpath}" \
  "$@"
